import {
  Column,
  Entity,
  ManyToOne,
  OneToMany,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { Unit } from '../units/unit.entity';
import { OrgKind } from './duty-roles';

/** A company HQ, platoon, platoon HQ, or squad within a unit. */
@Entity()
export class OrgElement {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  unitId: number;

  @ManyToOne(() => Unit, { onDelete: 'CASCADE' })
  unit: Unit;

  // null for top-level elements (Company HQ, platoons)
  @Column({ type: 'int', nullable: true })
  parentId: number | null;

  @ManyToOne(() => OrgElement, (el) => el.children, { onDelete: 'CASCADE' })
  parent: OrgElement | null;

  @OneToMany(() => OrgElement, (el) => el.parent)
  children: OrgElement[];

  @Column({ length: 60 })
  name: string;

  @Column({ type: 'varchar', length: 20 })
  kind: OrgKind;

  @Column({ default: 0 })
  sortOrder: number;
}
