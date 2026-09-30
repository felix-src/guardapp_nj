import {
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Unit } from './unit.entity';
import { PointOfContact } from './point-of-contact.entity';
import { CreateUnitDto } from './dto/create-unit.dto';
import { CreateContactDto } from './dto/create-contact.dto';
import { User } from '../auth/user.entity';
import { Role } from '../auth/roles.enum';
import {
  formatJoinCode,
  generateJoinCode,
  JOIN_CODE_TTL_MS,
  normalizeJoinCode,
} from './join-code';
import { isUniqueViolation } from '../common/db-errors';

@Injectable()
export class UnitsService {
  constructor(
    @InjectRepository(Unit)
    private readonly unitRepository: Repository<Unit>,
    @InjectRepository(PointOfContact)
    private readonly contactRepository: Repository<PointOfContact>,
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
  ) {}

  findAll() {
    return this.unitRepository.find({ order: { name: 'ASC' } });
  }

  async findOne(id: number) {
    const unit = await this.unitRepository.findOne({
      where: { id },
      relations: { contacts: true },
      order: { contacts: { position: 'ASC' } },
    });
    if (!unit) throw new NotFoundException('Unit not found');
    return unit;
  }

  create(unit: CreateUnitDto) {
    const newUnit = this.unitRepository.create(unit);
    return this.unitRepository.save(newUnit);
  }

  async findContacts(unitId: number) {
    await this.ensureUnitExists(unitId);
    return this.contactRepository.find({
      where: { unitId },
      order: { position: 'ASC' },
    });
  }

  async addContact(unitId: number, dto: CreateContactDto) {
    await this.ensureUnitExists(unitId);
    const contact = this.contactRepository.create({
      ...dto,
      phone: dto.phone ?? null,
      email: dto.email ?? null,
      unitId,
    });
    return this.contactRepository.save(contact);
  }

  async removeContact(unitId: number, contactId: number) {
    const result = await this.contactRepository.delete({
      id: contactId,
      unitId,
    });
    if (!result.affected) throw new NotFoundException('Contact not found');
  }

  /**
   * Current join code for a unit. Codes rotate weekly: an expired (or
   * missing) code is replaced the next time the NCO asks for it.
   */
  async getJoinCode(unitId: number) {
    const unit = await this.unitRepository
      .createQueryBuilder('unit')
      .addSelect(['unit.joinCode', 'unit.joinCodeExpiresAt'])
      .where('unit.id = :unitId', { unitId })
      .getOne();
    if (!unit) throw new NotFoundException('Unit not found');

    if (
      !unit.joinCode ||
      !unit.joinCodeExpiresAt ||
      unit.joinCodeExpiresAt.getTime() <= Date.now()
    ) {
      return this.rotateJoinCode(unitId);
    }

    return this.toJoinCodeResponse(unit.joinCode, unit.joinCodeExpiresAt);
  }

  /** Replaces the unit's join code; the old code stops working immediately. */
  async rotateJoinCode(unitId: number) {
    await this.ensureUnitExists(unitId);
    const expiresAt = new Date(Date.now() + JOIN_CODE_TTL_MS);

    // 31^8 codes make a collision very unlikely; retry just in case.
    for (let attempt = 0; attempt < 5; attempt++) {
      const code = generateJoinCode();
      try {
        await this.unitRepository.update(unitId, {
          joinCode: code,
          joinCodeExpiresAt: expiresAt,
        });
        return this.toJoinCodeResponse(code, expiresAt);
      } catch (err: unknown) {
        if (!isUniqueViolation(err)) throw err;
      }
    }
    throw new Error('Could not generate a unique join code');
  }

  /** The unit a still-valid join code belongs to, or null. */
  async findUnitByJoinCode(input: string): Promise<Unit | null> {
    const code = normalizeJoinCode(input);
    if (!code) return null;

    return this.unitRepository
      .createQueryBuilder('unit')
      .where('unit.joinCode = :code', { code })
      .andWhere('unit.joinCodeExpiresAt > now()')
      .getOne();
  }

  async listMembers(unitId: number) {
    await this.ensureUnitExists(unitId);
    return this.userRepository.find({
      where: { unitId },
      select: ['id', 'email', 'firstName', 'lastName', 'rank', 'role'],
      order: { lastName: 'ASC', firstName: 'ASC' },
    });
  }

  /** Deletes a soldier's account. NCOs and admins can't be removed here. */
  async removeMember(unitId: number, userId: number) {
    const user = await this.userRepository.findOneBy({ id: userId, unitId });
    if (!user) throw new NotFoundException('Member not found');
    if (user.role !== Role.Soldier) {
      throw new ForbiddenException('Only soldier accounts can be removed');
    }
    await this.userRepository.delete(user.id);
  }

  /** Throws unless the user belongs to the unit. */
  async ensureMember(unitId: number, userId: number) {
    const exists = await this.userRepository.existsBy({ id: userId, unitId });
    if (!exists) throw new NotFoundException('Member not found');
  }

  async ensureUnitExists(id: number) {
    const exists = await this.unitRepository.existsBy({ id });
    if (!exists) throw new NotFoundException('Unit not found');
  }

  private toJoinCodeResponse(code: string, expiresAt: Date) {
    const base = process.env.JOIN_BASE_URL ?? 'http://localhost:8080/join';
    const formatted = formatJoinCode(code);
    return {
      code: formatted,
      expiresAt,
      joinUrl: `${base}?code=${formatted}`,
    };
  }
}
