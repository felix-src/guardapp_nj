import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Unit } from './unit.entity';

@Injectable()
export class UnitsService {
  constructor(
    @InjectRepository(Unit)
    private readonly unitRepository: Repository<Unit>,
  ) {}

  findAll() {
    return this.unitRepository.find();
  }

  findOne(id: number) {
    return this.unitRepository.findOneBy({ id });
  }

  create(unit: { name: string; state: string }) {
    const newUnit = this.unitRepository.create(unit);
    return this.unitRepository.save(newUnit);
  }
}
