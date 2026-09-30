import { MigrationInterface, QueryRunner } from 'typeorm';

export class SessionSecurity1790695999566 implements MigrationInterface {
  name = 'SessionSecurity1790695999566';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "user" ADD "tokenVersion" integer NOT NULL DEFAULT '0'`,
    );
    await queryRunner.query(
      `ALTER TABLE "user" ADD "failedLoginCount" integer NOT NULL DEFAULT '0'`,
    );
    await queryRunner.query(
      `ALTER TABLE "user" ADD "lockedUntil" TIMESTAMP WITH TIME ZONE`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(`ALTER TABLE "user" DROP COLUMN "lockedUntil"`);
    await queryRunner.query(
      `ALTER TABLE "user" DROP COLUMN "failedLoginCount"`,
    );
    await queryRunner.query(`ALTER TABLE "user" DROP COLUMN "tokenVersion"`);
  }
}
