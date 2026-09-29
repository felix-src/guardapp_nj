import {
  IsEnum,
  IsInt,
  IsNotEmpty,
  IsOptional,
  IsString,
  MaxLength,
  Min,
} from 'class-validator';
import { OrgKind } from '../duty-roles';

export class CreateOrgElementDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(60)
  name: string;

  @IsEnum(OrgKind)
  kind: OrgKind;

  // Omit for a new platoon; set to a platoon's id for a squad or HQ
  @IsOptional()
  @IsInt()
  @Min(1)
  parentId?: number;
}
