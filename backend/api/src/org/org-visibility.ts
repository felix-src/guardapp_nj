// Need-to-know rules for the org chart. Enforced on the server: data a
// viewer shouldn't see is never sent, so a stolen phone can't reveal it.
import { Role } from '../auth/roles.enum';
import { DutyRole, OrgKind } from './duty-roles';

/** Duty roles that see the whole company (and full names). */
export const COMPANY_WIDE_ROLES: readonly DutyRole[] = [
  'commander',
  'executive_officer',
  'first_sergeant',
  'platoon_leader',
  'platoon_sergeant',
  'readiness_nco',
];

/** Duty roles that see full names: squad leaders and up. */
export const FULL_NAME_ROLES: readonly DutyRole[] = [
  ...COMPANY_WIDE_ROLES,
  'squad_leader',
];

export interface OrgAccess {
  /** false: only Company HQ and the viewer's own platoon */
  companyWide: boolean;
  /** false: rank, last name, and first initial only */
  fullNames: boolean;
}

export function orgAccess(appRole: Role, dutyRole: string | null): OrgAccess {
  // Admins and the unit's Readiness NCO account manage the whole roster
  if (appRole === Role.Admin || appRole === Role.ReadinessNco) {
    return { companyWide: true, fullNames: true };
  }
  const role = dutyRole as DutyRole;
  return {
    companyWide: COMPANY_WIDE_ROLES.includes(role),
    fullNames: FULL_NAME_ROLES.includes(role),
  };
}

// Structural types so this file doesn't depend on the service's DTOs
interface MemberLike {
  firstName: string | null;
  firstInitial?: string | null;
}
interface NodeLike<M extends MemberLike> {
  id: number;
  kind: OrgKind;
  children: NodeLike<M>[];
  members?: M[];
}

/**
 * Trims an org chart to what the viewer may see. [viewerPlatoonId] is the
 * platoon containing the viewer's position (null if they're in Company HQ
 * or unassigned).
 */
export function restrictOrgChart<M extends MemberLike, N extends NodeLike<M>>(
  chart: { structure: N[]; unassigned: M[] },
  access: OrgAccess,
  viewerPlatoonId: number | null,
): { structure: N[]; unassigned: M[] } {
  const structure = access.companyWide
    ? chart.structure
    : chart.structure.filter(
        (top) => top.kind === OrgKind.CompanyHq || top.id === viewerPlatoonId,
      );
  const unassigned = access.companyWide ? chart.unassigned : [];

  if (!access.fullNames) {
    const abbreviate = (m: M) => {
      m.firstInitial = m.firstName ? m.firstName[0].toUpperCase() : null;
      m.firstName = null;
    };
    const walk = (nodes: NodeLike<M>[]) =>
      nodes.forEach((n) => {
        n.members?.forEach(abbreviate);
        walk(n.children);
      });
    walk(structure);
    unassigned.forEach(abbreviate);
  }

  return { structure, unassigned };
}
