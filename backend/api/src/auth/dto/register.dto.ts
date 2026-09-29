import {
  IsEmail,
  IsInt,
  IsNotEmpty,
  IsString,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';

export class RegisterDto {
  @IsEmail()
  email: string;

  @IsString()
  @MinLength(8)
  @MaxLength(72) // bcrypt ignores bytes past 72
  password: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(50)
  firstName: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(50)
  lastName: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(10)
  rank: string;

  // Unit join code from the Readiness NCO's link
  @IsString()
  @IsNotEmpty()
  @MaxLength(20)
  unitCode: string;

  // Squad/section/HQ from GET /auth/join/:code
  @IsInt()
  @Min(1)
  orgElementId: number;

  // Duty role key allowed for that element
  @IsString()
  @MaxLength(40)
  dutyRole: string;
}
