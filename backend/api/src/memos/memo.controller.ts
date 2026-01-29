import {
  Controller,
  Get,
  Post,
  UseGuards,
  Req,
  Param,
  UploadedFile,
  UseInterceptors,
  Body,
  Res,
} from '@nestjs/common';

import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';

import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname } from 'path';

import type { Response } from 'express';

import { Memo } from './memo.entity';
import { AuditService } from '../audit/audit.service';
import { JwtAuthGuard } from '../auth/jwt-auth.guard';
import { AdminGuard } from '../auth/admin.guard';


@Controller('memos')
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
  async download(@Param('id') id: string, @Res() res: Response) {
    const memo = await this.memoRepo.findOneBy({ id: Number(id) });
    if (!memo) {
      return res.status(404).json({ message: 'Memo not found' });
    }

    return res.download(`uploads/memos/${memo.filename}`);
  }

  // Upload PDF (admin only)
  @Post()
  @UseGuards(JwtAuthGuard, AdminGuard)
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: './uploads/memos',
        filename: (req, file, cb) => {
          const uniqueName =
            'memo-' + Date.now() + extname(file.originalname);
          cb(null, uniqueName);
        },
      }),
      fileFilter: (req, file, cb) => {
        if (file.mimetype !== 'application/pdf') {
          return cb(new Error('Only PDF files are allowed'), false);
        }
        cb(null, true);
      },
    }),
  )
  async upload(
    @UploadedFile() file: Express.Multer.File,
    @Body('title') title: string,
    @Req() req: any,
  ) {
    const memo = this.memoRepo.create({
      title,
      filename: file.filename,
      authorId: req.user.sub,
      authorRole: req.user.role,
    });

    const saved = await this.memoRepo.save(memo);

    await this.auditService.log(
      req.user.sub,
      req.user.role,
      'UPLOAD_MEMO_PDF',
      '/memos',
    );

    return saved;
  }
}
