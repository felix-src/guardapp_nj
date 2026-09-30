import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './user.entity';
import * as bcrypt from 'bcrypt';
import { JwtService } from '@nestjs/jwt';
import { RegisterDto } from './dto/register.dto';
import { UnitsService } from '../units/units.service';
import { OrgService } from '../org/org.service';
import { DUTY_ROLES, isDutyRole } from '../org/duty-roles';
import { AuditService } from '../audit/audit.service';
import { isUniqueViolation } from '../common/db-errors';
import { afterFailedLogin, isLocked, MAX_FAILED_LOGINS } from './lockout';
import type { JwtPayload } from './auth-user';

const BCRYPT_ROUNDS = 12;

// Compared against when the email doesn't exist, so a login attempt takes
// the same time whether or not the account exists.
const DUMMY_HASH = bcrypt.hashSync('timing-equalizer-not-a-password', 12);

// One message for every failed login: doesn't reveal whether the email
// exists or the account is locked.
const LOGIN_FAILED = `Invalid email or password. After ${MAX_FAILED_LOGINS} failed attempts the account is locked for 15 minutes.`;

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    private readonly jwtService: JwtService,
    private readonly unitsService: UnitsService,
    private readonly orgService: OrgService,
    private readonly auditService: AuditService,
  ) {}

  /** Unit name and structure for the sign-up form, if the code is valid. */
  async lookupJoinCode(code: string) {
    const unit = await this.findUnitOrThrow(code);
    return {
      unitName: unit.name,
      structure: await this.orgService.getStructure(unit.id),
    };
  }

  /** Self sign-up: the unit join code decides which unit the soldier joins. */
  async register(dto: RegisterDto) {
    const unit = await this.findUnitOrThrow(dto.unitCode);
    await this.orgService.validatePosition(
      unit.id,
      dto.orgElementId,
      dto.dutyRole,
    );

    const user = await this.createUser(dto.email, dto.password, {
      firstName: dto.firstName.trim(),
      lastName: dto.lastName.trim(),
      rank: dto.rank.trim(),
      unitId: unit.id,
      orgElementId: dto.orgElementId,
      dutyRole: dto.dutyRole,
    });

    await this.auditService.log(
      user.id,
      user.role,
      'REGISTER',
      '/auth/register',
    );

    return {
      id: user.id,
      email: user.email,
      role: user.role,
      unitId: unit.id,
      unitName: unit.name,
    };
  }

  private async findUnitOrThrow(code: string) {
    const unit = await this.unitsService.findUnitByJoinCode(code);
    if (!unit) {
      throw new BadRequestException(
        'Invalid or expired unit code. Ask your Readiness NCO for a current link.',
      );
    }
    return unit;
  }

  async createUser(
    email: string,
    password: string,
    profile: Partial<
      Pick<
        User,
        | 'firstName'
        | 'lastName'
        | 'rank'
        | 'unitId'
        | 'orgElementId'
        | 'dutyRole'
      >
    > = {},
  ) {
    const normalizedEmail = email.trim().toLowerCase();
    if (await this.userRepo.existsBy({ email: normalizedEmail })) {
      throw new ConflictException('An account with this email already exists');
    }

    const passwordHash = await bcrypt.hash(password, BCRYPT_ROUNDS);
    const user = this.userRepo.create({
      email: normalizedEmail,
      passwordHash,
      ...profile,
    });

    try {
      return await this.userRepo.save(user);
    } catch (err: unknown) {
      // Two sign-ups racing for the same email
      if (isUniqueViolation(err)) {
        throw new ConflictException(
          'An account with this email already exists',
        );
      }
      throw err;
    }
  }

  async login(email: string, password: string) {
    const user = await this.userRepo.findOneBy({
      email: email.trim().toLowerCase(),
    });

    const valid = await bcrypt.compare(
      password,
      user?.passwordHash ?? DUMMY_HASH,
    );
    if (!user) throw new UnauthorizedException(LOGIN_FAILED);

    if (isLocked(user)) {
      // Even a correct password doesn't get in while locked
      await this.auditService.log(
        user.id,
        user.role,
        'LOGIN_WHILE_LOCKED',
        '/auth/login',
      );
      throw new UnauthorizedException(LOGIN_FAILED);
    }

    if (!valid) {
      const next = afterFailedLogin(user);
      await this.userRepo.update(user.id, next);
      await this.auditService.log(
        user.id,
        user.role,
        next.lockedUntil ? 'ACCOUNT_LOCKED' : 'LOGIN_FAILED',
        '/auth/login',
      );
      throw new UnauthorizedException(LOGIN_FAILED);
    }

    if (user.failedLoginCount > 0 || user.lockedUntil) {
      await this.userRepo.update(user.id, {
        failedLoginCount: 0,
        lockedUntil: null,
      });
    }
    await this.auditService.log(user.id, user.role, 'LOGIN', '/auth/login');

    return { access_token: this.issueToken(user) };
  }

  /** Invalidates every token issued so far for this account. */
  async revokeSessions(userId: number) {
    const result = await this.userRepo.increment(
      { id: userId },
      'tokenVersion',
      1,
    );
    if (!result.affected) throw new NotFoundException('User not found');
  }

  /** Changes the password and signs out every other device. Returns a fresh
   * token for this device. */
  async changePassword(
    userId: number,
    currentPassword: string,
    newPassword: string,
  ) {
    const user = await this.userRepo.findOneBy({ id: userId });
    if (!user) throw new NotFoundException('User not found');

    if (!(await bcrypt.compare(currentPassword, user.passwordHash))) {
      throw new BadRequestException('Current password is incorrect');
    }
    if (currentPassword === newPassword) {
      throw new BadRequestException(
        'New password must be different from the current one',
      );
    }

    user.passwordHash = await bcrypt.hash(newPassword, BCRYPT_ROUNDS);
    user.tokenVersion += 1;
    await this.userRepo.save(user);
    await this.auditService.log(
      user.id,
      user.role,
      'CHANGE_PASSWORD',
      '/auth/change-password',
    );

    return { access_token: this.issueToken(user) };
  }

  /** Admin recovery (create-admin --reset-password): sets a new password,
   * clears any lockout, and signs out every device. */
  async resetPassword(userId: number, newPassword: string) {
    const user = await this.userRepo.findOneBy({ id: userId });
    if (!user) throw new NotFoundException('User not found');

    user.passwordHash = await bcrypt.hash(newPassword, BCRYPT_ROUNDS);
    user.tokenVersion += 1;
    user.failedLoginCount = 0;
    user.lockedUntil = null;
    await this.userRepo.save(user);
    await this.auditService.log(
      user.id,
      user.role,
      'RESET_PASSWORD',
      'create-admin',
    );
  }

  private issueToken(user: User) {
    const payload: JwtPayload = { sub: user.id, ver: user.tokenVersion };
    return this.jwtService.sign(payload);
  }

  /** Profile for the app's home header: who, which unit, which position. */
  async getProfile(userId: number) {
    const user = await this.userRepo.findOne({
      where: { id: userId },
      relations: { unit: true, orgElement: { parent: true } },
    });
    if (!user) throw new NotFoundException('User not found');

    const element = user.orgElement;
    return {
      id: user.id,
      email: user.email,
      role: user.role,
      firstName: user.firstName,
      lastName: user.lastName,
      rank: user.rank,
      unitId: user.unitId,
      unitName: user.unit?.name ?? null,
      dutyRole: user.dutyRole,
      dutyRoleLabel:
        user.dutyRole && isDutyRole(user.dutyRole)
          ? DUTY_ROLES[user.dutyRole]
          : null,
      // e.g. "2nd Squad, 1st Platoon" or "Company HQ"
      position: element
        ? [element.name, element.parent?.name].filter(Boolean).join(', ')
        : null,
    };
  }
}
