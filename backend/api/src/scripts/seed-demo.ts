// Adds clearly labeled sample units, points of contact, and a memo for local
// testing. Safe to re-run; skips anything that already exists.
// Usage: npm run seed:demo            (add sample data)
//        npm run seed:demo -- --remove  (delete it again)
import * as dotenv from 'dotenv';
dotenv.config();

import { existsSync, mkdirSync, unlinkSync, writeFileSync } from 'fs';
import { join } from 'path';
import { NestFactory } from '@nestjs/core';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Like, Repository } from 'typeorm';
import { AppModule } from '../app.module';
import { Unit } from '../units/unit.entity';
import { PointOfContact } from '../units/point-of-contact.entity';
import { Memo } from '../memos/memo.entity';

const UNIT_SUFFIX = ' (Sample)';
const MEMO_PREFIX = 'Sample: ';
const MEMO_FILE = 'memo-sample-welcome.pdf';
const MEMO_DIR = join('uploads', 'memos');

type SampleContact = Pick<
  PointOfContact,
  'name' | 'position' | 'phone' | 'email'
>;

// Fictional contact details only: 555-01xx numbers and example.com addresses.
const SAMPLE_UNITS: {
  name: string;
  state: string;
  contacts: SampleContact[];
}[] = [
  {
    name: 'HHC, 1st Battalion',
    state: 'NJ',
    contacts: [
      {
        name: 'CPT Alex Rivera',
        position: 'Company Commander',
        phone: '609-555-0101',
        email: 'alex.rivera@example.com',
      },
      {
        name: '1SG Morgan Lee',
        position: 'First Sergeant',
        phone: '609-555-0102',
        email: 'morgan.lee@example.com',
      },
      {
        name: 'SSG Casey Kim',
        position: 'Readiness NCO',
        phone: '609-555-0103',
        email: null,
      },
    ],
  },
  {
    name: 'Alpha Company, 1st Battalion',
    state: 'NJ',
    contacts: [
      {
        name: 'CPT Jordan Patel',
        position: 'Company Commander',
        phone: '609-555-0111',
        email: 'jordan.patel@example.com',
      },
      {
        name: 'SFC Taylor Brooks',
        position: 'Training NCO',
        phone: null,
        email: 'taylor.brooks@example.com',
      },
    ],
  },
  {
    name: 'Brigade Support Battalion',
    state: 'NJ',
    contacts: [],
  },
];

async function main() {
  const remove = process.argv.includes('--remove');
  const app = await NestFactory.createApplicationContext(AppModule, {
    logger: ['error'],
  });

  try {
    const units = app.get<Repository<Unit>>(getRepositoryToken(Unit));
    const contacts = app.get<Repository<PointOfContact>>(
      getRepositoryToken(PointOfContact),
    );
    const memos = app.get<Repository<Memo>>(getRepositoryToken(Memo));

    if (remove) {
      const u = await units.delete({ name: Like(`%${UNIT_SUFFIX}`) });
      const m = await memos.delete({ title: Like(`${MEMO_PREFIX}%`) });
      const file = join(MEMO_DIR, MEMO_FILE);
      if (existsSync(file)) unlinkSync(file);
      console.log(
        `Removed ${u.affected ?? 0} sample units (and their contacts), ${m.affected ?? 0} sample memos.`,
      );
      return;
    }

    for (const sample of SAMPLE_UNITS) {
      const name = sample.name + UNIT_SUFFIX;
      if (await units.existsBy({ name })) {
        console.log(`Skipping existing unit: ${name}`);
        continue;
      }
      const unit = await units.save(
        units.create({ name, state: sample.state }),
      );
      await contacts.save(
        sample.contacts.map((c) => contacts.create({ ...c, unitId: unit.id })),
      );
      console.log(`Added ${name} with ${sample.contacts.length} contacts`);
    }

    const memoTitle = `${MEMO_PREFIX}Welcome to the Guard Resource App`;
    if (await memos.existsBy({ title: memoTitle })) {
      console.log(`Skipping existing memo: ${memoTitle}`);
    } else {
      mkdirSync(MEMO_DIR, { recursive: true });
      writeFileSync(
        join(MEMO_DIR, MEMO_FILE),
        buildPdf([
          'SAMPLE MEMO - FOR TESTING ONLY',
          '',
          'This memo was created by npm run seed:demo.',
          'Remove it with: npm run seed:demo -- --remove',
        ]),
      );
      await memos.save(
        memos.create({
          title: memoTitle,
          filename: MEMO_FILE,
          authorId: 0,
          authorRole: 'system',
        }),
      );
      console.log(`Added memo: ${memoTitle}`);
    }
  } finally {
    await app.close();
  }
}

// Minimal single-page PDF with one line of Helvetica text per entry.
function buildPdf(lines: string[]): Buffer {
  const escape = (s: string) => s.replace(/[\\()]/g, (c) => '\\' + c);
  const text = lines
    .map(
      (l, i) =>
        `BT /F1 ${i === 0 ? 16 : 12} Tf 72 ${720 - i * 24} Td (${escape(l)}) Tj ET`,
    )
    .join('\n');
  const objects = [
    '<< /Type /Catalog /Pages 2 0 R >>',
    '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
    '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << /Font << /F1 5 0 R >> >> >>',
    `<< /Length ${Buffer.byteLength(text)} >>\nstream\n${text}\nendstream`,
    '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
  ];

  let pdf = '%PDF-1.4\n';
  const offsets: number[] = [];
  objects.forEach((obj, i) => {
    offsets.push(Buffer.byteLength(pdf));
    pdf += `${i + 1} 0 obj\n${obj}\nendobj\n`;
  });
  const xrefStart = Buffer.byteLength(pdf);
  pdf += `xref\n0 ${objects.length + 1}\n0000000000 65535 f \n`;
  pdf += offsets
    .map((o) => `${String(o).padStart(10, '0')} 00000 n \n`)
    .join('');
  pdf += `trailer\n<< /Size ${objects.length + 1} /Root 1 0 R >>\nstartxref\n${xrefStart}\n%%EOF\n`;
  return Buffer.from(pdf, 'latin1');
}

main().catch((err: unknown) => {
  console.error(err instanceof Error ? err.message : err);
  process.exit(1);
});
