import { IsInt, IsString, MaxLength, Min } from 'class-validator';

export class SetPositionDto {
  @IsInt()
  @Min(1)
  orgElementId: number;

  @IsString()
  @MaxLength(40)
  dutyRole: string;
}
