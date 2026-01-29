import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { UnitsController } from './units/units.controller';
import { UnitsService } from './units/units.service';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Unit } from './units/unit.entity';
import { User } from './auth/user.entity';
import { AuthService } from './auth/auth.service';
import { AuthController } from './auth/auth.controller';
import { JwtModule } from '@nestjs/jwt';
import { MiddlewareConsumer} from '@nestjs/common';
import { LoggerMiddleware } from './common/logger.middleware';
import { AuditLog } from './audit/audit-log.entity';
import { AuditService } from './audit/audit.service';
import { AuditController } from './audit/audit.controller';
import { AdminUserController } from './auth/admin.controller';
import { Memo } from './memos/memo.entity';
import { MemoController } from './memos/memo.controller';


@Module({
  imports: [  
    TypeOrmModule.forRoot({
  type: 'postgres',
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT),
  username: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  entities: [Unit, User, AuditLog, Memo],
  synchronize: true,
}),
TypeOrmModule.forFeature([Unit, User, AuditLog, Memo]),
JwtModule.register({
  secret: process.env.JWT_SECRET,
  signOptions: { expiresIn: '1h' },
}),

],
  controllers: [UnitsController, AppController, AuthController, AuditController,AdminUserController, MemoController],
  providers: [AppService, UnitsService, AuthService, AuditService],
})
export class AppModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(LoggerMiddleware).forRoutes('*');
  }
}
