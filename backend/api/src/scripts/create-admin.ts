// Creates an admin account, or promotes an existing account to admin.
// Usage: npm run create-admin -- <email>
// The password is prompted for (or read from ADMIN_PASSWORD) so it never
// lands in shell history.
import * as dotenv from 'dotenv';
dotenv.config();

import * as readline from 'readline';
import { NestFactory } from '@nestjs/core';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AppModule } from '../app.module';
import { AuthService } from '../auth/auth.service';
import { User } from '../auth/user.entity';
import { Role } from '../auth/roles.enum';

function promptHidden(question: string): Promise<string> {
  return new Promise((resolve) => {
    const rl = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
      terminal: true,
    });
    const rlAny = rl as any;
    const write = rlAny._writeToOutput?.bind(rl);
    rlAny._writeToOutput = (s: string) => {
      if (s.startsWith(question)) write(question);
    };
    rl.question(question, (answer) => {
      rl.close();
      process.stdout.write('\n');
      resolve(answer);
    });
  });
}

async function main() {
  const email = process.argv[2]?.trim().toLowerCase();
  if (!email) {
    console.error('Usage: npm run create-admin -- <email>');
    process.exit(1);
  }

  const app = await NestFactory.createApplicationContext(AppModule, {
    logger: ['error'],
  });

  try {
    const users = app.get<Repository<User>>(getRepositoryToken(User));
    let user = await users.findOneBy({ email });

    if (user) {
      console.log(`Account ${email} exists; promoting to admin.`);
    } else {
      const password =
        process.env.ADMIN_PASSWORD ?? (await promptHidden('Password: '));
      if (password.length < 8) {
        throw new Error('Password must be at least 8 characters');
      }
      user = await app.get(AuthService).createUser(email, password);
      console.log(`Created account ${email}.`);
    }

    user.role = Role.Admin;
    await users.save(user);
    console.log(`${email} is now an admin.`);
  } finally {
    await app.close();
  }
}

main().catch((err) => {
  console.error(err.message ?? err);
  process.exit(1);
});
