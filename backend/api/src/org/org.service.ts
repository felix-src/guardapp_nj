import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { DataSource, EntityManager, In, Repository } from 'typeorm';
import { OrgElement } from './org-element.entity';
import { User } from '../auth/user.entity';
import {
  DUTY_ROLES,
  dutyRoleOrder,
  INFANTRY_COMPANY_TEMPLATE,
  isDutyRole,
  OrgKind,
  PLATOON_CHILD_KINDS,
  ROLES_BY_KIND,
  TemplateElement,
} from './duty-roles';
import { CreateOrgElementDto } from './dto/create-org-element.dto';
import { Role } from '../auth/roles.enum';
import { orgAccess, restrictOrgChart } from './org-visibility';

export interface OrgMemberView {
  id: number;
  rank: string | null;
  firstName: string | null;
  lastName: string | null;
  dutyRole: string | null;
  dutyRoleLabel: string | null;
  /** Set instead of firstName for viewers without full-name access */
  firstInitial?: string | null;
}

export interface OrgNode {
  id: number;
  name: string;
  kind: OrgKind;
  roles: { key: string; label: string }[];
  children: OrgNode[];
  members?: OrgMemberView[];
}

@Injectable()
export class OrgService {
  constructor(
    @InjectRepository(OrgElement)
    private readonly elementRepo: Repository<OrgElement>,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    private readonly dataSource: DataSource,
  ) {}

  /** The unit's platoons/squads with the roles each accepts (no members). */
  async getStructure(unitId: number): Promise<OrgNode[]> {
    await this.ensureStructure(unitId);
    const elements = await this.elementRepo.find({
      where: { unitId },
      order: { sortOrder: 'ASC', id: 'ASC' },
    });
    return this.buildTree(elements);
  }

  /** The org chart as [viewer] may see it (see org-visibility.ts): the
   * whole company or just Company HQ + their platoon, with full or
   * abbreviated names. Access is re-read from the database every time. */
  async getOrgChart(unitId: number, viewer: { id: number; role: Role }) {
    const self = await this.userRepo.findOne({
      where: { id: viewer.id },
      relations: { orgElement: true },
    });
    // Role from the database, not the JWT, so demotions apply immediately
    const access = orgAccess(
      viewer.role === Role.Admin ? Role.Admin : (self?.role ?? Role.Soldier),
      self?.dutyRole ?? null,
    );
    const viewerPlatoonId =
      self?.unitId === unitId ? (self.orgElement?.parentId ?? null) : null;

    const chart = await this.buildOrgChart(unitId);
    return {
      ...restrictOrgChart(chart, access, viewerPlatoonId),
      access,
    };
  }

  /** Full chart: structure plus who holds which position, with people who
   * have no position listed separately as unassigned. No emails. */
  private async buildOrgChart(unitId: number) {
    const structure = await this.getStructure(unitId);
    const users = await this.userRepo.find({
      where: { unitId },
      select: [
        'id',
        'rank',
        'firstName',
        'lastName',
        'dutyRole',
        'orgElementId',
      ],
    });

    const byElement = new Map<number, OrgMemberView[]>();
    const unassigned: OrgMemberView[] = [];
    const leafIds = new Set<number>();
    const collect = (nodes: OrgNode[]) =>
      nodes.forEach((n) => {
        if (n.kind !== OrgKind.Platoon) leafIds.add(n.id);
        collect(n.children);
      });
    collect(structure);

    for (const user of users) {
      const view: OrgMemberView = {
        id: user.id,
        rank: user.rank,
        firstName: user.firstName,
        lastName: user.lastName,
        dutyRole: user.dutyRole,
        dutyRoleLabel:
          user.dutyRole && isDutyRole(user.dutyRole)
            ? DUTY_ROLES[user.dutyRole]
            : null,
      };
      if (user.orgElementId && leafIds.has(user.orgElementId)) {
        const list = byElement.get(user.orgElementId) ?? [];
        list.push(view);
        byElement.set(user.orgElementId, list);
      } else {
        unassigned.push(view);
      }
    }

    const sortMembers = (list: OrgMemberView[]) =>
      list.sort(
        (a, b) =>
          dutyRoleOrder(a.dutyRole) - dutyRoleOrder(b.dutyRole) ||
          (a.lastName ?? '').localeCompare(b.lastName ?? ''),
      );
    const attach = (nodes: OrgNode[]) =>
      nodes.forEach((n) => {
        if (n.kind !== OrgKind.Platoon) {
          n.members = sortMembers(byElement.get(n.id) ?? []);
        }
        attach(n.children);
      });
    attach(structure);

    return { structure, unassigned: sortMembers(unassigned) };
  }

  /** Throws unless [elementId] is a position-holding element of the unit and
   * [dutyRole] fits it. */
  async validatePosition(unitId: number, elementId: number, dutyRole: string) {
    await this.ensureStructure(unitId);
    const element = await this.elementRepo.findOneBy({ id: elementId, unitId });
    if (!element || element.kind === OrgKind.Platoon) {
      throw new BadRequestException('Choose a squad, section, or HQ');
    }
    if (
      !isDutyRole(dutyRole) ||
      !ROLES_BY_KIND[element.kind].includes(dutyRole)
    ) {
      throw new BadRequestException(
        `That duty role isn't part of ${element.name}`,
      );
    }
    return element;
  }

  async setMemberPosition(
    unitId: number,
    userId: number,
    elementId: number,
    dutyRole: string,
  ) {
    const user = await this.userRepo.findOneBy({ id: userId, unitId });
    if (!user) throw new NotFoundException('Member not found');
    await this.validatePosition(unitId, elementId, dutyRole);
    await this.userRepo.update(userId, { orgElementId: elementId, dutyRole });
  }

  async addElement(unitId: number, dto: CreateOrgElementDto) {
    await this.ensureStructure(unitId);

    if (dto.parentId == null) {
      if (dto.kind !== OrgKind.Platoon) {
        throw new BadRequestException(
          'Only platoons can be added at the company level',
        );
      }
    } else {
      const parent = await this.elementRepo.findOneBy({
        id: dto.parentId,
        unitId,
      });
      if (!parent || parent.kind !== OrgKind.Platoon) {
        throw new BadRequestException('Squads can only be added to a platoon');
      }
      if (!PLATOON_CHILD_KINDS.includes(dto.kind)) {
        throw new BadRequestException(
          'A platoon can hold a platoon HQ, rifle squads, or weapons squads',
        );
      }
    }

    return this.dataSource.transaction(async (manager) => {
      const parentId = dto.parentId ?? null;
      const created = await this.insertElement(manager, unitId, parentId, {
        name: dto.name.trim(),
        kind: dto.kind,
        // A new platoon gets its HQ so its leadership has somewhere to go
        children:
          dto.kind === OrgKind.Platoon
            ? [{ name: 'Platoon HQ', kind: OrgKind.PlatoonHq }]
            : undefined,
      });
      return created;
    });
  }

  async renameElement(unitId: number, elementId: number, name: string) {
    const element = await this.elementRepo.findOneBy({ id: elementId, unitId });
    if (!element) throw new NotFoundException('Element not found');
    element.name = name.trim();
    return this.elementRepo.save(element);
  }

  /** Deletes an element (and a platoon's squads) if nobody is assigned. */
  async deleteElement(unitId: number, elementId: number) {
    const element = await this.elementRepo.findOneBy({ id: elementId, unitId });
    if (!element) throw new NotFoundException('Element not found');
    if (element.kind === OrgKind.CompanyHq) {
      throw new BadRequestException('Company HQ cannot be deleted');
    }

    const children = await this.elementRepo.findBy({ parentId: element.id });
    const ids = [element.id, ...children.map((c) => c.id)];
    const assigned = await this.userRepo.countBy({ orgElementId: In(ids) });
    if (assigned > 0) {
      throw new ConflictException(
        `Move the ${assigned} soldier${assigned === 1 ? '' : 's'} assigned here first`,
      );
    }

    // Children go with it (FK cascade)
    await this.elementRepo.delete(element.id);
  }

  /** Creates the infantry template the first time a unit's structure is
   * needed. The unit row lock stops two requests creating it twice. */
  private async ensureStructure(unitId: number) {
    if (await this.elementRepo.existsBy({ unitId })) return;

    await this.dataSource.transaction(async (manager) => {
      const locked = await manager.query(
        'SELECT id FROM unit WHERE id = $1 FOR UPDATE',
        [unitId],
      );
      if (locked.length === 0) throw new NotFoundException('Unit not found');
      if (await manager.existsBy(OrgElement, { unitId })) return;

      for (const element of INFANTRY_COMPANY_TEMPLATE) {
        await this.insertElement(manager, unitId, null, element);
      }
    });
  }

  private async insertElement(
    manager: EntityManager,
    unitId: number,
    parentId: number | null,
    template: TemplateElement,
  ): Promise<OrgElement> {
    const siblingMax = await manager
      .createQueryBuilder(OrgElement, 'el')
      .select('COALESCE(MAX(el.sortOrder), -1)', 'max')
      .where('el.unitId = :unitId', { unitId })
      .andWhere(
        parentId == null ? 'el.parentId IS NULL' : 'el.parentId = :parentId',
        { parentId },
      )
      .getRawOne<{ max: number }>();

    const saved = await manager.save(
      manager.create(OrgElement, {
        unitId,
        parentId,
        name: template.name,
        kind: template.kind,
        sortOrder: Number(siblingMax?.max ?? -1) + 1,
      }),
    );
    for (const child of template.children ?? []) {
      await this.insertElement(manager, unitId, saved.id, child);
    }
    return saved;
  }

  private buildTree(elements: OrgElement[]): OrgNode[] {
    const nodes = new Map<number, OrgNode>();
    for (const el of elements) {
      nodes.set(el.id, {
        id: el.id,
        name: el.name,
        kind: el.kind,
        roles: ROLES_BY_KIND[el.kind].map((key) => ({
          key,
          label: DUTY_ROLES[key],
        })),
        children: [],
      });
    }

    const roots: OrgNode[] = [];
    for (const el of elements) {
      const node = nodes.get(el.id)!;
      const parent = el.parentId == null ? undefined : nodes.get(el.parentId);
      (parent ? parent.children : roots).push(node);
    }
    return roots;
  }
}
