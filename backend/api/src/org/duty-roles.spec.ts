import {
  DUTY_ROLES,
  dutyRoleOrder,
  INFANTRY_COMPANY_TEMPLATE,
  isDutyRole,
  OrgKind,
  PLATOON_CHILD_KINDS,
  ROLES_BY_KIND,
  TemplateElement,
} from './duty-roles';

describe('duty roles and company template', () => {
  it('only assigns known duty roles to each kind', () => {
    for (const roles of Object.values(ROLES_BY_KIND)) {
      for (const role of roles) expect(isDutyRole(role)).toBe(true);
    }
  });

  it('builds a two-level template matching the kind rules', () => {
    const check = (el: TemplateElement, depth: number) => {
      if (depth === 0) {
        expect([OrgKind.CompanyHq, OrgKind.Platoon]).toContain(el.kind);
      } else {
        expect(PLATOON_CHILD_KINDS).toContain(el.kind);
      }
      if (el.kind === OrgKind.Platoon) {
        expect(el.children?.length).toBeGreaterThan(0);
      } else {
        expect(el.children).toBeUndefined();
        expect(ROLES_BY_KIND[el.kind].length).toBeGreaterThan(0);
      }
      el.children?.forEach((child) => check(child, depth + 1));
    };
    INFANTRY_COMPANY_TEMPLATE.forEach((el) => check(el, 0));
    expect(
      INFANTRY_COMPANY_TEMPLATE.filter((el) => el.kind === OrgKind.CompanyHq),
    ).toHaveLength(1);
  });

  it('sorts leadership first and unknown roles last', () => {
    expect(dutyRoleOrder('commander')).toBeLessThan(dutyRoleOrder('rifleman'));
    expect(dutyRoleOrder('squad_leader')).toBeLessThan(
      dutyRoleOrder('team_leader'),
    );
    expect(dutyRoleOrder(null)).toBe(Object.keys(DUTY_ROLES).length);
  });
});
