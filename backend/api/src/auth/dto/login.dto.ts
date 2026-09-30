import { IsEmail, IsNotEmpty, IsString, MaxLength } from 'class-validator';

// No length rules here: policy applies to new passwords only, and login
// shouldn't hint at what the rules are.
export class LoginDto {
  @IsEmail()
  email: string;

  @IsString()
  @IsNotEmpty()
  @MaxLength(128)
  password: string;
}
