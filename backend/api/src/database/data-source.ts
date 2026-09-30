// Database connection shared by the app (AppModule) and the TypeORM CLI
// (npm run migration:*). Schema changes go through migrations in
// ./migrations; never enable `synchronize`, which can silently alter or
// drop columns.
import * as dotenv from 'dotenv';
dotenv.config({ quiet: true });

import { DataSource, DataSourceOptions } from 'typeorm';
import { Unit } from '../units/unit.entity';
import { PointOfContact } from '../units/point-of-contact.entity';
import { User } from '../auth/user.entity';
import { AuditLog } from '../audit/audit-log.entity';
import { Memo } from '../memos/memo.entity';
import { OrgElement } from '../org/org-element.entity';

export const dataSourceOptions: DataSourceOptions = {
  type: 'postgres',
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT),
  username: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  entities: [Unit, PointOfContact, User, AuditLog, Memo, OrgElement],
  migrations: [__dirname + '/migrations/*.{ts,js}'],
  synchronize: false,
};

export default new DataSource(dataSourceOptions);
