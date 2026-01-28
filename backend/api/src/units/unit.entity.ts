import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity()
export class Unit {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  name: string;

  @Column()
  state: string;
}
