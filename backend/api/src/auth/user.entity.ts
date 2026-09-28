import { Entity, PrimaryGeneratedColumn, Column, ManyToOne } from 'typeorm';
import { Role } from './roles.enum';
import { Unit } from '../units/unit.entity';

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
}
