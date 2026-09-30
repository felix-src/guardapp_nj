import {
  BadRequestException,
  Body,
  Controller,
  Get,
  NotFoundException,
  Param,
  ParseIntPipe,
  Post,
  Res,
  UploadedFile,
  UseGuards,
  UseInterceptors,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { FileInterceptor } from '@nestjs/platform-express';
import { memoryStorage } from 'multer';
import { randomUUID } from 'crypto';
import { mkdir, writeFile } from 'fs/promises';
import { basename, join, resolve } from 'path';
import type { Response } from 'express';

import { Memo } from './memo.entity';
import { CreateMemoDto } from './dto/create-memo.dto';
import { looksLikePdf } from './pdf';
import { AuditService } from '../audit/audit.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AdminGuard } from '../auth/admin.guard';
import { CurrentUser } from '../auth/current-user.decorator';
import type { AuthUser } from '../auth/auth-user';

const MEMO_DIR = resolve('uploads', 'memos');
const MAX_MEMO_BYTES = 10 * 1024 * 1024;

@Controller('memos')
@UseGuards(JwtAuthGuard)
export class MemoController {
  constructor(
    @InjectRepository(Memo)
    private readonly memoRepo: Repository<Memo>,
    private readonly auditService: AuditService,
  ) {}

  // List memo metadata
  @Get()
  async list() {
    return this.memoRepo.find({
      order: { createdAt: 'DESC' },
    });
  }

  // Download PDF
  @Get(':id/download')
  async download(@Param('id', ParseIntPipe) id: number, @Res() res: Response) {
    const memo = await this.memoRepo.findOneBy({ id });
    if (!memo) throw new NotFoundException('Memo not found');

    // basename(): a stored name can never point outside the memo folder
    res.download(join(MEMO_DIR, basename(memo.filename)), `${memo.id}.pdf`);
  }

  // Upload PDF (admin only). Held in memory and checked before anything is
  // written to disk.
  @Post()
  @UseGuards(AdminGuard)
  @UseInterceptors(
    FileInterceptor('file', {
      storage: memoryStorage(),
      limits: { fileSize: MAX_MEMO_BYTES, files: 1 },
    }),
  )
  async upload(
    @UploadedFile() file: Express.Multer.File | undefined,
    @Body() body: CreateMemoDto,
    @CurrentUser() user: AuthUser,
  ) {
    if (!file) throw new BadRequestException('Attach a PDF as "file"');
    if (!looksLikePdf(file.buffer)) {
      throw new BadRequestException('Only PDF files are allowed');
    }

    // Random name: nothing from the client ends up in the file path
    const filename = `memo-${randomUUID()}.pdf`;
    await mkdir(MEMO_DIR, { recursive: true });
    await writeFile(join(MEMO_DIR, filename), file.buffer);

    const saved = await this.memoRepo.save(
      this.memoRepo.create({
        title: body.title.trim(),
        filename,
        authorId: user.id,
        authorRole: user.role,
      }),
    );

    await this.auditService.log(
      user.id,
      user.role,
      'UPLOAD_MEMO_PDF',
      '/memos',
    );

    return saved;
  }
}
