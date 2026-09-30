import { Entity, PrimaryGeneratedColumn, Column, ManyToOne } from 'typeorm';
import { Role } from './roles.enum';
import { Unit } from '../units/unit.entity';
import { OrgElement } from '../org/org-element.entity';

@Entity()
export class User {
  @PrimaryGeneratedColumn()
  id: number;

  @Column({ unique: true })
  email: string;

  @Column()
  passwordHash: string;

  @Column({
    type: 'enum',
    enum: Role,
    default: Role.Soldier,
  })
  role: Role;

  // Nullable: accounts made with create-admin have no name or unit
  @Column({ type: 'varchar', nullable: true })
  firstName: string | null;

  @Column({ type: 'varchar', nullable: true })
  lastName: string | null;

  @Column({ type: 'varchar', nullable: true })
  rank: string | null;

  @Column({ type: 'int', nullable: true })
  unitId: number | null;

  @ManyToOne(() => Unit, (unit) => unit.members, { onDelete: 'SET NULL' })
  unit: Unit | null;

  // Position in the unit's org chart; null = unassigned
  @Column({ type: 'int', nullable: true })
  orgElementId: number | null;

  @ManyToOne(() => OrgElement, { onDelete: 'SET NULL' })
  orgElement: OrgElement | null;

  // Key from org/duty-roles.ts DUTY_ROLES
  @Column({ type: 'varchar', nullable: true })
  dutyRole: string | null;

  // Signed into every token; bumping it signs the account out everywhere
  // (lost phone, password change)
  @Column({ default: 0 })
  tokenVersion: number;

  // Account lockout (see auth/lockout.ts)
  @Column({ default: 0 })
  failedLoginCount: number;

  @Column({ type: 'timestamptz', nullable: true })
  lockedUntil: Date | null;
}
