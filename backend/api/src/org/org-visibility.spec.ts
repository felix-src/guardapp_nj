import { Role } from '../auth/roles.enum';
import { OrgKind } from './duty-roles';
import { orgAccess, restrictOrgChart } from './org-visibility';

const member = (firstName: string) => ({
  firstName,
  firstInitial: null as string | null,
});

function sampleChart() {
  return {
    structure: [
      {
        id: 1,
        kind: OrgKind.CompanyHq,
        children: [],
        members: [member('Jordan')],
      },
      {
        id: 2,
        kind: OrgKind.Platoon,
        children: [
          {
            id: 3,
            kind: OrgKind.RifleSquad,
            children: [],
            members: [member('Pat')],
          },
        ],
      },
      {
        id: 4,
        kind: OrgKind.Platoon,
        children: [
          {
            id: 5,
            kind: OrgKind.RifleSquad,
            children: [],
            members: [member('Lee')],
          },
        ],
      },
    ],
    unassigned: [member('Sam')],
  };
}

describe('orgAccess', () => {
  it('gives admins and the NCO account everything', () => {
    for (const role of [Role.Admin, Role.ReadinessNco]) {
      expect(orgAccess(role, null)).toEqual({
        companyWide: true,
        fullNames: true,
      });
    }
  });

  it('gives company and platoon leadership the whole company', () => {
    for (const duty of ['commander', 'first_sergeant', 'platoon_sergeant']) {
      expect(orgAccess(Role.Soldier, duty)).toEqual({
        companyWide: true,
        fullNames: true,
      });
    }
  });

  it('gives squad leaders full names but only their platoon', () => {
    expect(orgAccess(Role.Soldier, 'squad_leader')).toEqual({
      companyWide: false,
      fullNames: true,
    });
  });

  it('restricts everyone else, including unassigned soldiers', () => {
    for (const duty of ['team_leader', 'rifleman', 'rto', null]) {
      expect(orgAccess(Role.Soldier, duty)).toEqual({
        companyWide: false,
        fullNames: false,
      });
    }
  });
});

describe('restrictOrgChart', () => {
  it('keeps everything for company-wide full-name access', () => {
    const chart = restrictOrgChart(
      sampleChart(),
      { companyWide: true, fullNames: true },
      null,
    );
    expect(chart.structure.map((n) => n.id)).toEqual([1, 2, 4]);
    expect(chart.unassigned).toHaveLength(1);
    expect(chart.structure[1].children[0].members?.[0].firstName).toBe('Pat');
  });

  it('shows only Company HQ and the viewer platoon, abbreviated', () => {
    const chart = restrictOrgChart(
      sampleChart(),
      { companyWide: false, fullNames: false },
      2,
    );
    expect(chart.structure.map((n) => n.id)).toEqual([1, 2]);
    expect(chart.unassigned).toEqual([]);

    const pat = chart.structure[1].children[0].members[0];
    expect(pat.firstName).toBeNull();
    expect(pat.firstInitial).toBe('P');
    expect(JSON.stringify(chart)).not.toContain('Jordan');
    expect(JSON.stringify(chart)).not.toContain('Lee');
  });

  it('shows only Company HQ to a viewer with no platoon', () => {
    const chart = restrictOrgChart(
      sampleChart(),
      { companyWide: false, fullNames: true },
      null,
    );
    expect(chart.structure.map((n) => n.id)).toEqual([1]);
    expect(chart.structure[0].members?.[0].firstName).toBe('Jordan');
  });
});
