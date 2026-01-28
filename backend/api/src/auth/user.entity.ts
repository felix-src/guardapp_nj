import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';
import { Role } from './roles.enum';

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
}
