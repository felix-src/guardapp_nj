// Curated links shown in the app's Resources & Benefits and Jobs screens.
// Served by the API (not bundled in the app) so links can be fixed without
// an App Store release. Links verified 2026-09-28. Note: in January 2026 NJ
// DMAVA split into the Dept. of Military Affairs (nj.gov/dma) and the
// Dept. of Veterans Affairs (nj.gov/dva); old nj.gov/military links redirect.

export interface ResourceLink {
  title: string;
  description: string;
  url: string;
  /** Digits to dial, e.g. "6095304600" */
  phone?: string;
  /** How to show the number, e.g. "609-530-4600" */
  phoneLabel?: string;
}

export interface ResourceGroup {
  title: string;
  /** Icon key the app maps to an icon (school, family, benefits, ...) */
  icon: string;
  items: ResourceLink[];
}

export const CRISIS_LINE: ResourceLink = {
  title: 'Military & Veterans Crisis Line',
  description:
    'Free, confidential support 24/7 for service members, veterans, and their families. Call 988 and press 1, or text 838255.',
  url: 'https://www.veteranscrisisline.net/',
  phone: '988',
  phoneLabel: '988, then press 1',
};

export const NEW_JERSEY_RESOURCES: ResourceGroup[] = [
  {
    title: 'Education',
    icon: 'school',
    items: [
      {
        title: 'NJ National Guard Tuition Program',
        description:
          'Tuition-free courses (up to 16 credits per semester) at New Jersey public colleges for eligible Guard members. Fees and materials not covered; file the FAFSA first.',
        url: 'https://education.njarmyguard.com/njngtp',
      },
      {
        title: 'NJ Army Guard Education Services Office',
        description:
          'Help with the tuition waiver, Federal Tuition Assistance, and the GI Bill.',
        url: 'https://education.njarmyguard.com/',
      },
      {
        title: 'NJ Air National Guard Education',
        description:
          'Education benefits and contacts for NJ Air Guard members.',
        url: 'https://www.njang.ang.af.mil/About-Us/Education/',
      },
    ],
  },
  {
    title: 'Family Support',
    icon: 'family',
    items: [
      {
        title: 'NJ National Guard Family Programs',
        description:
          'Family Assistance Centers, Survivor Outreach, Yellow Ribbon, youth programs, and transition support.',
        url: 'https://www.nj.gov/dma/support/family-programs/',
        phone: '6095304600',
        phoneLabel: '609-530-4600',
      },
      {
        title: 'Family Assistance Centers',
        description:
          'ID cards and DEERS, TRICARE help, emergency financial and legal referrals, and crisis support.',
        url: 'https://www.nj.gov/dma/support/family-programs/programs-services/facs/',
      },
      {
        title: 'JB MDL Military & Family Readiness Center',
        description:
          'Joint Base McGuire-Dix-Lakehurst services open to all branches.',
        url: 'https://gomdl.com/military-family-readiness-center/',
      },
    ],
  },
  {
    title: 'State Benefits',
    icon: 'benefits',
    items: [
      {
        title: 'New Jersey Benefits for Guard Members',
        description:
          'State taxes, education, employment preference, MVC, free hunting and fishing licenses, state parks, and more.',
        url: 'https://myarmybenefits.us.army.mil/Benefit-Library/State/Territory-Benefits/New-Jersey',
      },
      {
        title: 'NJ Department of Veterans Affairs',
        description:
          'State veterans benefits, programs, and advocacy for service members and families.',
        url: 'https://www.nj.gov/dva/',
        phone: '18888658387',
        phoneLabel: '1-888-8NJ-VETS',
      },
      {
        title: 'NJ Department of Military Affairs',
        description: "The New Jersey National Guard's state headquarters.",
        url: 'https://www.nj.gov/dma/',
      },
    ],
  },
];

export const NATIONAL_RESOURCES: ResourceGroup[] = [
  {
    title: 'Support & Counseling',
    icon: 'support',
    items: [
      {
        title: 'Military OneSource',
        description:
          'Free 24/7 confidential counseling, financial and legal help, and relocation support.',
        url: 'https://www.militaryonesource.mil/',
        phone: '8003429647',
        phoneLabel: '800-342-9647',
      },
      {
        title: 'National Guard Family Program',
        description:
          'Family readiness, financial awareness, psychological health, and transition resources.',
        url: 'https://www.jointservicessupport.org/fp/default.aspx',
      },
    ],
  },
  {
    title: 'Health & Insurance',
    icon: 'health',
    items: [
      {
        title: 'TRICARE Reserve Select',
        description:
          'Premium-based health plan for Selected Reserve members and families.',
        url: 'https://www.tricare.mil/trs',
      },
      {
        title: 'SGLI Life Insurance',
        description:
          "Servicemembers' Group Life Insurance coverage and options.",
        url: 'https://www.va.gov/life-insurance/options-eligibility/sgli/',
      },
    ],
  },
  {
    title: 'Education',
    icon: 'school',
    items: [
      {
        title: 'Federal Tuition Assistance',
        description:
          'Army TA toward certificates and degrees, requested through ArmyIgnitED.',
        url: 'https://myarmybenefits.us.army.mil/Benefit-Library/Federal-Benefits/Tuition-Assistance-(TA)',
      },
      {
        title: 'GI Bill & VA Education',
        description:
          'Montgomery GI Bill Selected Reserve, Post-9/11 GI Bill, and other VA education benefits.',
        url: 'https://www.va.gov/education/',
      },
    ],
  },
  {
    title: 'Financial & Employment',
    icon: 'benefits',
    items: [
      {
        title: 'Army Emergency Relief',
        description:
          'Zero-interest loans and grants for eligible soldiers and families; check eligibility for your duty status.',
        url: 'https://www.armyemergencyrelief.org/',
      },
      {
        title: 'ESGR',
        description:
          'Employer Support of the Guard and Reserve: your civilian job rights (USERRA) and employer outreach.',
        url: 'https://www.esgr.mil/',
      },
      {
        title: 'My Army Benefits',
        description: 'The official Army benefits library and calculators.',
        url: 'https://myarmybenefits.us.army.mil/',
      },
    ],
  },
];

export const JOB_SECTIONS: ResourceGroup[] = [
  {
    title: 'New Jersey National Guard',
    icon: 'work',
    items: [
      {
        title: 'Federal Technician Jobs',
        description:
          'Army and Air Guard dual-status technician vacancies. Dual-status positions require membership in the NJ National Guard.',
        url: 'https://www.nj.gov/dma/admin/vacancy/',
      },
      {
        title: 'AGR Jobs',
        description:
          'Active Guard Reserve vacancies for the Army and Air Guard, plus AGR reassignments. The same page lists ADOS tours and DMA state jobs.',
        url: 'https://www.nj.gov/dma/admin/vacancy/',
      },
      {
        title: 'HRO Recruitment & Placement',
        description:
          'How technician and AGR hiring works, NGB Form 34-1, and a resume sample.',
        url: 'https://www.nj.gov/dma/guard/joint-staff/j1-hro/recruitment.shtml',
      },
    ],
  },
  {
    title: 'Federal Jobs',
    icon: 'search',
    items: [
      {
        title: 'USAJOBS: National Guard in New Jersey',
        description:
          'All federal technician announcements are posted on USAJOBS; apply there.',
        url: 'https://www.usajobs.gov/search/results/?l=New%20Jersey&k=National%20Guard',
      },
    ],
  },
];
