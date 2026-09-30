// Company organization: a two-level tree per unit.
//   Top level:  Company HQ (holds members) or Platoon (container only)
//   Under a platoon: Platoon HQ, rifle squads, weapons squads/sections
export enum OrgKind {
  CompanyHq = 'company_hq',
  Platoon = 'platoon',
  PlatoonHq = 'platoon_hq',
  RifleSquad = 'rifle_squad',
  WeaponsSquad = 'weapons_squad',
}

/** Kinds an NCO can add under a platoon. */
export const PLATOON_CHILD_KINDS = [
  OrgKind.PlatoonHq,
  OrgKind.RifleSquad,
  OrgKind.WeaponsSquad,
];

// Duty positions (not app permissions — see auth/roles.enum.ts). Listed in
// chain-of-command order, which is also how members are sorted in the chart.
export const DUTY_ROLES = {
  commander: 'Commander',
  executive_officer: 'Executive Officer',
  first_sergeant: 'First Sergeant',
  platoon_leader: 'Platoon Leader',
  platoon_sergeant: 'Platoon Sergeant',
  squad_leader: 'Squad Leader',
  team_leader: 'Team Leader',
  supply_sergeant: 'Supply Sergeant',
  readiness_nco: 'Readiness NCO',
  training_nco: 'Training NCO',
  forward_observer: 'Forward Observer',
  medic: 'Medic',
  rto: 'RTO',
  machine_gunner: 'Machine Gunner',
  assistant_gunner: 'Assistant Gunner',
  anti_armor_specialist: 'Anti-Armor Specialist',
  automatic_rifleman: 'Automatic Rifleman',
  grenadier: 'Grenadier',
  rifleman: 'Rifleman',
} as const;

export type DutyRole = keyof typeof DUTY_ROLES;

export const ROLES_BY_KIND: Record<OrgKind, DutyRole[]> = {
  [OrgKind.CompanyHq]: [
    'commander',
    'executive_officer',
    'first_sergeant',
    'supply_sergeant',
    'readiness_nco',
    'training_nco',
    'rto',
  ],
  [OrgKind.Platoon]: [], // members sit in the platoon's HQ or squads
  [OrgKind.PlatoonHq]: [
    'platoon_leader',
    'platoon_sergeant',
    'rto',
    'medic',
    'forward_observer',
  ],
  [OrgKind.RifleSquad]: [
    'squad_leader',
    'team_leader',
    'automatic_rifleman',
    'grenadier',
    'rifleman',
  ],
  [OrgKind.WeaponsSquad]: [
    'squad_leader',
    'machine_gunner',
    'assistant_gunner',
    'anti_armor_specialist',
  ],
};

export function isDutyRole(value: string): value is DutyRole {
  return Object.hasOwn(DUTY_ROLES, value);
}

const ROLE_ORDER = Object.keys(DUTY_ROLES);

/** Chain-of-command sort position; unknown roles sort last. */
export function dutyRoleOrder(role: string | null): number {
  const i = role ? ROLE_ORDER.indexOf(role) : -1;
  return i === -1 ? ROLE_ORDER.length : i;
}

export interface TemplateElement {
  name: string;
  kind: OrgKind;
  children?: TemplateElement[];
}

const riflePlatoon = (name: string): TemplateElement => ({
  name,
  kind: OrgKind.Platoon,
  children: [
    { name: 'Platoon HQ', kind: OrgKind.PlatoonHq },
    { name: '1st Squad', kind: OrgKind.RifleSquad },
    { name: '2nd Squad', kind: OrgKind.RifleSquad },
    { name: '3rd Squad', kind: OrgKind.RifleSquad },
    { name: 'Weapons Squad', kind: OrgKind.WeaponsSquad },
  ],
});

/** Standard infantry rifle company; every unit starts from this. */
export const INFANTRY_COMPANY_TEMPLATE: TemplateElement[] = [
  { name: 'Company HQ', kind: OrgKind.CompanyHq },
  riflePlatoon('1st Platoon'),
  riflePlatoon('2nd Platoon'),
  riflePlatoon('3rd Platoon'),
  {
    name: 'Weapons Platoon',
    kind: OrgKind.Platoon,
    children: [
      { name: 'Platoon HQ', kind: OrgKind.PlatoonHq },
      { name: 'Mortar Section', kind: OrgKind.WeaponsSquad },
      { name: 'Assault Section', kind: OrgKind.WeaponsSquad },
    ],
  },
];
