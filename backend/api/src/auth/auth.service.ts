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

@Injectable()
export class AuthService {
  constructor(
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
    private readonly jwtService: JwtService,
    private readonly unitsService: UnitsService,
  ) {}

  /** Self sign-up: the unit join code decides which unit the soldier joins. */
  async register(dto: RegisterDto) {
    const unit = await this.unitsService.findUnitByJoinCode(dto.unitCode);
    if (!unit) {
      throw new BadRequestException(
        'Invalid or expired unit code. Ask your Readiness NCO for a current link.',
      );
    }

    const user = await this.createUser(dto.email, dto.password, {
      firstName: dto.firstName.trim(),
      lastName: dto.lastName.trim(),
      rank: dto.rank.trim(),
      unitId: unit.id,
    });

    return {
      id: user.id,
      email: user.email,
      role: user.role,
      unitId: unit.id,
      unitName: unit.name,
    };
  }

  async createUser(
    email: string,
    password: string,
    profile: Partial<
      Pick<User, 'firstName' | 'lastName' | 'rank' | 'unitId'>
    > = {},
  ) {
    const normalizedEmail = email.trim().toLowerCase();
    if (await this.userRepo.existsBy({ email: normalizedEmail })) {
      throw new ConflictException('An account with this email already exists');
    }

    const passwordHash = await bcrypt.hash(password, 10);
    const user = this.userRepo.create({
      email: normalizedEmail,
      passwordHash,
      ...profile,
    });

    try {
      return await this.userRepo.save(user);
    } catch (err: any) {
      // Two sign-ups racing for the same email
      if (err?.code === '23505') {
        throw new ConflictException(
          'An account with this email already exists',
        );
      }
      throw err;
    }
  }

  async validateUser(email: string, password: string): Promise<User | null> {
    const user = await this.userRepo.findOneBy({
      email: email.trim().toLowerCase(),
    });
    if (!user) return null;

    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) return null;

    return user;
  }

  async login(email: string, password: string) {
    const user = await this.validateUser(email, password);

    if (!user) {
      throw new UnauthorizedException('Invalid credentials');
    }

    const payload = {
      sub: user.id,
      role: user.role,
    };

    return {
      access_token: this.jwtService.sign(payload),
    };
  }

  async getProfile(userId: number) {
    const user = await this.userRepo.findOne({
      where: { id: userId },
      select: [
        'id',
        'email',
        'role',
        'firstName',
        'lastName',
        'rank',
        'unitId',
      ],
    });
    if (!user) throw new NotFoundException('User not found');
    return user;
  }
}
