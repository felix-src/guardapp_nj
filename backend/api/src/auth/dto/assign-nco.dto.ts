import { IsInt, Min } from 'class-validator';

export class AssignNcoDto {
  @IsInt()
  @Min(1)
  unitId: number;
}
