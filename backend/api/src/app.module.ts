import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { UnitsController } from './units/units.controller';
import { UnitsService } from './units/units.service';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Unit } from './units/unit.entity';
import { User } from './auth/user.entity';


@Module({
  imports: [  
    TypeOrmModule.forRoot({
  type: 'postgres',
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT),
  username: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  entities: [Unit],
  synchronize: true,
}),
TypeOrmModule.forFeature([Unit]),],
  controllers: [UnitsController, AppController],
  providers: [AppService, UnitsService],
})
export class AppModule {}
