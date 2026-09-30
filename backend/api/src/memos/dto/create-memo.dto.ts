import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class CreateMemoDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(150)
  title: string;
}
