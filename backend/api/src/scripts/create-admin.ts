// Creates an admin account, or promotes an existing account to admin.
// Usage: npm run create-admin -- <email> [--reset-password]
// --reset-password sets a new password on an existing account, clears any
// lockout, and signs it out on every device (admin recovery).
// Passwords are prompted for (or read from ADMIN_PASSWORD) so they never
// land in shell history.
import * as dotenv from 'dotenv';
dotenv.config({ quiet: true });

import * as readline from 'readline';
import { NestFactory } from '@nestjs/core';
import { getRepositoryToken } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { AppModule } from '../app.module';
import { AuthService } from '../auth/auth.service';
import { User } from '../auth/user.entity';
import { Role } from '../auth/roles.enum';
import {
  PASSWORD_MAX_LENGTH,
  PASSWORD_MIN_LENGTH,
} from '../auth/password-policy';

// readline has no public "hide input" option; this private hook is the
// usual way to stop it echoing what's typed.
type MaskableInterface = readline.Interface & {
  _writeToOutput?: (s: string) => void;
};

function promptHidden(question: string): Promise<string> {
  return new Promise((resolve) => {
    const rl: MaskableInterface = readline.createInterface({
      input: process.stdin,
      output: process.stdout,
      terminal: true,
    });
    rl._writeToOutput = (s: string) => {
      if (s.startsWith(question)) process.stdout.write(question);
    };
    rl.question(question, (answer) => {
      rl.close();
      process.stdout.write('\n');
      resolve(answer);
    });
  });
}

async function readNewPassword(): Promise<string> {
  const password =
    process.env.ADMIN_PASSWORD ?? (await promptHidden('New password: '));
  if (
    password.length < PASSWORD_MIN_LENGTH ||
    password.length > PASSWORD_MAX_LENGTH
  ) {
    throw new Error(
      `Password must be ${PASSWORD_MIN_LENGTH}-${PASSWORD_MAX_LENGTH} characters`,
    );
  }
  return password;
}

async function main() {
  const email = process.argv[2]?.trim().toLowerCase();
  const resetPassword = process.argv.includes('--reset-password');
  if (!email || email.startsWith('--')) {
    console.error('Usage: npm run create-admin -- <email> [--reset-password]');
    process.exit(1);
  }

  const app = await NestFactory.createApplicationContext(AppModule, {
    logger: ['error'],
  });

  try {
    const users = app.get<Repository<User>>(getRepositoryToken(User));
    const auth = app.get(AuthService);
    let user = await users.findOneBy({ email });

    if (user) {
      console.log(`Account ${email} exists; promoting to admin.`);
      if (resetPassword) {
        await auth.resetPassword(user.id, await readNewPassword());
        console.log('Password reset; all devices signed out.');
      }
    } else {
      user = await auth.createUser(email, await readNewPassword());
      console.log(`Created account ${email}.`);
    }

    await users.update(user.id, { role: Role.Admin });
    console.log(`${email} is now an admin.`);
  } finally {
    await app.close();
  }
}

main().catch((err: unknown) => {
  console.error(err instanceof Error ? err.message : err);
  process.exit(1);
});
