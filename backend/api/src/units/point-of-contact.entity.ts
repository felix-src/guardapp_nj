import { Entity, PrimaryGeneratedColumn, Column, ManyToOne } from 'typeorm';
import { Unit } from './unit.entity';

// Official duty contact info only (duty phone, .mil email) — no personal PII.
@Entity()
export class PointOfContact {
  @PrimaryGeneratedColumn()
  id: number;

  @Column()
  name: string;

  // Duty position, e.g. "Readiness NCO"
  @Column()
  position: string;

  @Column({ type: 'varchar', nullable: true })
  phone: string | null;

  @Column({ type: 'varchar', nullable: true })
  email: string | null;

  @Column()
  unitId: number;

  @ManyToOne(() => Unit, (unit) => unit.contacts, { onDelete: 'CASCADE' })
  unit: Unit;
}
