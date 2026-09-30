import {
  Injectable,
  CanActivate,
  ExecutionContext,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User } from './user.entity';
import type { AuthedRequest, JwtPayload } from './auth-user';

/**
 * Verifies the Bearer token, then loads the user from the database and
 * checks the token's version. A deleted account or a bumped tokenVersion
 * ("sign out everywhere", password change) rejects the token immediately,
 * not when it expires. Sets req.user (see CurrentUser).
 */
@Injectable()
export class JwtAuthGuard implements CanActivate {
  constructor(
    private readonly jwtService: JwtService,
    @InjectRepository(User)
    private readonly userRepo: Repository<User>,
  ) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<AuthedRequest>();
    const authHeader = request.headers.authorization;

    if (!authHeader) {
      throw new UnauthorizedException('Missing Authorization header');
    }

    const [scheme, token] = authHeader.split(' ');
    if (scheme !== 'Bearer' || !token) {
      throw new UnauthorizedException('Malformed Authorization header');
    }

    let payload: JwtPayload;
    try {
      payload = this.jwtService.verify<JwtPayload>(token);
    } catch {
      throw new UnauthorizedException('Invalid or expired token');
    }

    const user = await this.userRepo.findOne({
      where: { id: payload.sub },
      select: [
        'id',
        'role',
        'unitId',
        'orgElementId',
        'dutyRole',
        'tokenVersion',
      ],
    });
    if (!user || user.tokenVersion !== payload.ver) {
      throw new UnauthorizedException('Session expired');
    }

    request.user = {
      id: user.id,
      role: user.role,
      unitId: user.unitId,
      orgElementId: user.orgElementId,
      dutyRole: user.dutyRole,
    };
    return true;
  }
}
