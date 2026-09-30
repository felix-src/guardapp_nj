import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { UnitsController } from './units/units.controller';
import { UnitsService } from './units/units.service';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Unit } from './units/unit.entity';
import { PointOfContact } from './units/point-of-contact.entity';
import { User } from './auth/user.entity';
import { AuthService } from './auth/auth.service';
import { AuthController } from './auth/auth.controller';
import { JwtModule } from '@nestjs/jwt';
import { MiddlewareConsumer } from '@nestjs/common';
import { LoggerMiddleware } from './common/logger.middleware';
import { AuditLog } from './audit/audit-log.entity';
import { AuditService } from './audit/audit.service';
import { AuditController } from './audit/audit.controller';
import { AdminUserController } from './auth/admin.controller';
import { Memo } from './memos/memo.entity';
import { MemoController } from './memos/memo.controller';
import { ThrottlerGuard, ThrottlerModule } from '@nestjs/throttler';
import { APP_GUARD } from '@nestjs/core';
import { UnitScopeGuard } from './auth/unit-scope.guard';
import { UnitMemberGuard } from './auth/unit-member.guard';
import { OrgElement } from './org/org-element.entity';
import { OrgService } from './org/org.service';
import { OrgController } from './org/org.controller';
import { ResourcesController } from './resources/resources.controller';
import { dataSourceOptions } from './database/data-source';

@Module({
  imports: [
    // Pending migrations run at startup; the schema is never auto-synced
    TypeOrmModule.forRoot({ ...dataSourceOptions, migrationsRun: true }),
    TypeOrmModule.forFeature([
      Unit,
      PointOfContact,
      User,
      AuditLog,
      Memo,
      OrgElement,
    ]),
    // Global per-IP rate limit; AuthController sets tighter limits
    ThrottlerModule.forRoot([{ ttl: 60_000, limit: 120 }]),
    JwtModule.register({
      secret: process.env.JWT_SECRET,
      signOptions: {
        expiresIn: '1h',
        algorithm: 'HS256',
        issuer: 'guardapp-api',
        audience: 'guardapp',
      },
      verifyOptions: {
        algorithms: ['HS256'],
        issuer: 'guardapp-api',
        audience: 'guardapp',
      },
    }),
  ],
  controllers: [
    UnitsController,
    AppController,
    AuthController,
    AuditController,
    AdminUserController,
    MemoController,
    OrgController,
    ResourcesController,
  ],
  providers: [
    AppService,
    UnitsService,
    AuthService,
    AuditService,
    OrgService,
    UnitScopeGuard,
    UnitMemberGuard,
    { provide: APP_GUARD, useClass: ThrottlerGuard },
  ],
})
export class AppModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(LoggerMiddleware).forRoutes('*');
  }
}
