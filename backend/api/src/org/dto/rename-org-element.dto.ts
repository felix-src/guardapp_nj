import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class RenameOrgElementDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(60)
  name: string;
}
