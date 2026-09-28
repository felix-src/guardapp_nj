import { Entity, PrimaryGeneratedColumn, Column, OneToMany } from 'typeorm';
import { PointOfContact } from './point-of-contact.entity';
import { User } from '../auth/user.entity';

@Entity()
export class Unit {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  name: string;

  @Column()
  state: string;

  // Shared sign-up code. select: false keeps it out of every default query
  // (e.g. GET /units); read it only through UnitsService.getJoinCode.
  @Column({
    type: 'varchar',
    length: 8,
    nullable: true,
    unique: true,
    select: false,
  })
  joinCode: string | null;

  @Column({ type: 'timestamptz', nullable: true, select: false })
  joinCodeExpiresAt: Date | null;

  @OneToMany(() => PointOfContact, (contact) => contact.unit)
  contacts: PointOfContact[];

  @OneToMany(() => User, (user) => user.unit)
  members: User[];
}
