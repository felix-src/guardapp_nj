import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Unit } from './unit.entity';
import { PointOfContact } from './point-of-contact.entity';
import { CreateUnitDto } from './dto/create-unit.dto';
import { CreateContactDto } from './dto/create-contact.dto';

@Injectable()
export class UnitsService {
  constructor(
    @InjectRepository(Unit)
    private readonly unitRepository: Repository<Unit>,
    @InjectRepository(PointOfContact)
    private readonly contactRepository: Repository<PointOfContact>,
  ) {}

  findAll() {
    return this.unitRepository.find({ order: { name: 'ASC' } });
  }

  async findOne(id: number) {
    const unit = await this.unitRepository.findOne({
      where: { id },
      relations: { contacts: true },
      order: { contacts: { position: 'ASC' } },
    });
    if (!unit) throw new NotFoundException('Unit not found');
    return unit;
  }

  create(unit: CreateUnitDto) {
    const newUnit = this.unitRepository.create(unit);
    return this.unitRepository.save(newUnit);
  }

  async findContacts(unitId: number) {
    await this.ensureUnitExists(unitId);
    return this.contactRepository.find({
      where: { unitId },
      order: { position: 'ASC' },
    });
  }

  async addContact(unitId: number, dto: CreateContactDto) {
    await this.ensureUnitExists(unitId);
    const contact = this.contactRepository.create({
      ...dto,
      phone: dto.phone ?? null,
      email: dto.email ?? null,
      unitId,
    });
    return this.contactRepository.save(contact);
  }

  async removeContact(unitId: number, contactId: number) {
    const result = await this.contactRepository.delete({
      id: contactId,
      unitId,
    });
    if (!result.affected) throw new NotFoundException('Contact not found');
  }

  private async ensureUnitExists(id: number) {
    const exists = await this.unitRepository.existsBy({ id });
    if (!exists) throw new NotFoundException('Unit not found');
  }
}
