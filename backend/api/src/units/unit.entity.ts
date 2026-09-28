import { Entity, PrimaryGeneratedColumn, Column, OneToMany } from 'typeorm';
import { PointOfContact } from './point-of-contact.entity';

@Entity()
export class Unit {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  name: string;

  @Column()
  state: string;

  @OneToMany(() => PointOfContact, (contact) => contact.unit)
  contacts: PointOfContact[];
}
