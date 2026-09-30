import {
  IsEmail,
  IsInt,
  IsNotEmpty,
  IsString,
  MaxLength,
  Min,
  MinLength,
} from 'class-validator';
import { PASSWORD_MAX_LENGTH, PASSWORD_MIN_LENGTH } from '../password-policy';

export class RegisterDto {
  @IsEmail()
  email: string;

  @IsString()
  @MinLength(PASSWORD_MIN_LENGTH)
  @MaxLength(PASSWORD_MAX_LENGTH)
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
