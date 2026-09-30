import { MigrationInterface, QueryRunner } from 'typeorm';

export class Init1790695582603 implements MigrationInterface {
  name = 'Init1790695582603';

  public async up(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `CREATE TABLE "point_of_contact" ("id" SERIAL NOT NULL, "name" character varying NOT NULL, "position" character varying NOT NULL, "phone" character varying, "email" character varying, "unitId" integer NOT NULL, CONSTRAINT "PK_54cff1de5e8bb1cc73db05145d6" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "org_element" ("id" SERIAL NOT NULL, "unitId" integer NOT NULL, "parentId" integer, "name" character varying(60) NOT NULL, "kind" character varying(20) NOT NULL, "sortOrder" integer NOT NULL DEFAULT '0', CONSTRAINT "PK_d4ec0776a36d02cc9bb0c800bc8" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TYPE "public"."user_role_enum" AS ENUM('soldier', 'readiness_nco', 'admin')`,
    );
    await queryRunner.query(
      `CREATE TABLE "user" ("id" SERIAL NOT NULL, "email" character varying NOT NULL, "passwordHash" character varying NOT NULL, "role" "public"."user_role_enum" NOT NULL DEFAULT 'soldier', "firstName" character varying, "lastName" character varying, "rank" character varying, "unitId" integer, "orgElementId" integer, "dutyRole" character varying, CONSTRAINT "UQ_e12875dfb3b1d92d7d7c5377e22" UNIQUE ("email"), CONSTRAINT "PK_cace4a159ff9f2512dd42373760" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "unit" ("id" SERIAL NOT NULL, "name" character varying NOT NULL, "state" character varying NOT NULL, "joinCode" character varying(8), "joinCodeExpiresAt" TIMESTAMP WITH TIME ZONE, CONSTRAINT "UQ_fa19cb3f67eb3aa2df2adba3d1e" UNIQUE ("joinCode"), CONSTRAINT "PK_4252c4be609041e559f0c80f58a" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "audit_log" ("id" SERIAL NOT NULL, "userId" integer NOT NULL, "role" character varying NOT NULL, "action" character varying NOT NULL, "endpoint" character varying NOT NULL, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_07fefa57f7f5ab8fc3f52b3ed0b" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `CREATE TABLE "memo" ("id" SERIAL NOT NULL, "title" character varying NOT NULL, "filename" character varying NOT NULL, "authorId" integer NOT NULL, "authorRole" character varying NOT NULL, "createdAt" TIMESTAMP NOT NULL DEFAULT now(), CONSTRAINT "PK_612b46ac33a01fda3efb085302d" PRIMARY KEY ("id"))`,
    );
    await queryRunner.query(
      `ALTER TABLE "point_of_contact" ADD CONSTRAINT "FK_e7da8c3a43c643e4c9fc50d70a0" FOREIGN KEY ("unitId") REFERENCES "unit"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "org_element" ADD CONSTRAINT "FK_4caff6af96c674362c4040420c7" FOREIGN KEY ("unitId") REFERENCES "unit"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "org_element" ADD CONSTRAINT "FK_e00dc7321897996ae8fa679f723" FOREIGN KEY ("parentId") REFERENCES "org_element"("id") ON DELETE CASCADE ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "user" ADD CONSTRAINT "FK_856a1f0347b672d3b8bb4693bd8" FOREIGN KEY ("unitId") REFERENCES "unit"("id") ON DELETE SET NULL ON UPDATE NO ACTION`,
    );
    await queryRunner.query(
      `ALTER TABLE "user" ADD CONSTRAINT "FK_d11dc37d36b899cb4ce48c6392c" FOREIGN KEY ("orgElementId") REFERENCES "org_element"("id") ON DELETE SET NULL ON UPDATE NO ACTION`,
    );
  }

  public async down(queryRunner: QueryRunner): Promise<void> {
    await queryRunner.query(
      `ALTER TABLE "user" DROP CONSTRAINT "FK_d11dc37d36b899cb4ce48c6392c"`,
    );
    await queryRunner.query(
      `ALTER TABLE "user" DROP CONSTRAINT "FK_856a1f0347b672d3b8bb4693bd8"`,
    );
    await queryRunner.query(
      `ALTER TABLE "org_element" DROP CONSTRAINT "FK_e00dc7321897996ae8fa679f723"`,
    );
    await queryRunner.query(
      `ALTER TABLE "org_element" DROP CONSTRAINT "FK_4caff6af96c674362c4040420c7"`,
    );
    await queryRunner.query(
      `ALTER TABLE "point_of_contact" DROP CONSTRAINT "FK_e7da8c3a43c643e4c9fc50d70a0"`,
    );
    await queryRunner.query(`DROP TABLE "memo"`);
    await queryRunner.query(`DROP TABLE "audit_log"`);
    await queryRunner.query(`DROP TABLE "unit"`);
    await queryRunner.query(`DROP TABLE "user"`);
    await queryRunner.query(`DROP TYPE "public"."user_role_enum"`);
    await queryRunner.query(`DROP TABLE "org_element"`);
    await queryRunner.query(`DROP TABLE "point_of_contact"`);
  }
}
