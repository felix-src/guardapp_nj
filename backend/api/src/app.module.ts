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


@Module({
  imports: [  
    TypeOrmModule.forRoot({
  type: 'postgres',
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT),
  username: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  entities: [Unit, User, AuditLog],
  synchronize: true,
}),
TypeOrmModule.forFeature([Unit, User, AuditLog]),
JwtModule.register({
  secret: process.env.JWT_SECRET,
  signOptions: { expiresIn: '1h' },
}),

],
  controllers: [UnitsController, AppController, AuthController],
  providers: [AppService, UnitsService, AuthService, AuditService],
})
export class AppModule {
  configure(consumer: MiddlewareConsumer) {
    consumer.apply(LoggerMiddleware).forRoutes('*');
  }
}
