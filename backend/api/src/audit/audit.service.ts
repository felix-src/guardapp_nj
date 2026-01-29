import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AuditLog } from './audit-log.entity';

@Injectable()
export class AuditService {
  constructor(
    @InjectRepository(AuditLog)
    private readonly auditRepo: Repository<AuditLog>,
  ) {}

  async log(
    userId: number,
    role: string,
    action: string,
    endpoint: string,
  ) {
    const record = this.auditRepo.create({
      userId,
      role,
      action,
      endpoint,
    });

    await this.auditRepo.save(record);
  }
}
