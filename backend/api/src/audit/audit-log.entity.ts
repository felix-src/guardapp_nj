import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';

@Entity()
export class AuditLog {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  userId: number;

  @Column()
  role: string;

  @Column()
  action: string;

  @Column()
  endpoint: string;

  @CreateDateColumn()
  createdAt: Date;
}
