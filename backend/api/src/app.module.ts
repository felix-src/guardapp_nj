import { Module } from '@nestjs/common';
import { AppController } from './app.controller';
import { AppService } from './app.service';
import { UnitsController } from './units/units.controller';
import { UnitsService } from './units/units.service';
import { TypeOrmModule } from '@nestjs/typeorm';
import { Unit } from './units/unit.entity';

@Module({
  imports: [  TypeOrmModule.forRoot({
    type: 'postgres',
  host: 'localhost',
  port: 5432,
  username: 'postgres',
  password: 'secondtonone',
  database: 'guard_app',
  entities: [Unit],
  synchronize: true,
  }),TypeOrmModule.forFeature([Unit]),],
  controllers: [UnitsController, AppController],
  providers: [AppService, UnitsService],
})
export class AppModule {}
