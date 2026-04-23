// FAROL custom icons — 24×24, 2px stroke, round caps.

function makeIcon(paths, { size = 24, color = '#374151', fill } = {}) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none"
      stroke={color} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
      {paths}
    </svg>
  );
}

// 1. Benefit card (fork + card)
const IconBenefit = (p) => makeIcon(
  <>
    <rect x="3" y="6" width="18" height="13" rx="2"/>
    <path d="M9 10v3m0-3h-1.5a1.5 1.5 0 00-1.5 1.5V13m3-3v3m0 0a1.5 1.5 0 001.5-1.5V10M7.5 13v2"/>
    <path d="M14 11h4M14 14h3"/>
  </>, p
);

// 2. FGTS (building + coin accent)
const IconFGTS = (p) => makeIcon(
  <>
    <path d="M4 20V9l8-5 8 5v11"/>
    <path d="M4 20h16"/>
    <path d="M9 20v-5h6v5"/>
    <circle cx="12" cy="11" r="1.5"/>
  </>, p
);

// 3. CLT salary (briefcase + R$)
const IconCLT = (p) => makeIcon(
  <>
    <rect x="3" y="7" width="18" height="13" rx="2"/>
    <path d="M9 7V5a2 2 0 012-2h2a2 2 0 012 2v2"/>
    <path d="M10 15h3a1.5 1.5 0 000-3h-3v6m0-3l4 3"/>
  </>, p
);

// 4. Farol score (lighthouse + badge)
const IconScore = (p) => makeIcon(
  <>
    <path d="M10 21V9h4v12"/>
    <path d="M8 21h8"/>
    <path d="M11 9V6h2v3"/>
    <path d="M12 2v2"/>
    <path d="M12 4l3 3M12 4l-3 3"/>
  </>, p
);

// 5. Parcela/installment (calendar + split)
const IconParcela = (p) => makeIcon(
  <>
    <rect x="3" y="5" width="18" height="16" rx="2"/>
    <path d="M3 10h18"/>
    <path d="M8 3v4M16 3v4"/>
    <path d="M9 15h2M13 15h2"/>
  </>, p
);

// Generic UI icons used in the prototype
const IconHome = (p) => makeIcon(
  <><path d="M3 11l9-8 9 8v10a1 1 0 01-1 1h-5v-6h-6v6H4a1 1 0 01-1-1V11z"/></>, p
);
const IconChart = (p) => makeIcon(
  <><path d="M4 20V10M10 20V4M16 20v-8M22 20H2"/></>, p
);
const IconWallet = (p) => makeIcon(
  <>
    <path d="M3 7a2 2 0 012-2h13a1 1 0 011 1v3"/>
    <rect x="3" y="7" width="18" height="12" rx="2"/>
    <circle cx="16.5" cy="13" r="1.25" fill="currentColor" stroke="none"/>
  </>, p
);
const IconUser = (p) => makeIcon(
  <>
    <circle cx="12" cy="8" r="4"/>
    <path d="M4 21c0-4 4-6 8-6s8 2 8 6"/>
  </>, p
);
const IconPlus = (p) => makeIcon(<><path d="M12 5v14M5 12h14"/></>, p);
const IconBell = (p) => makeIcon(
  <>
    <path d="M6 9a6 6 0 1112 0c0 5 2 6 2 6H4s2-1 2-6z"/>
    <path d="M10 19a2 2 0 004 0"/>
  </>, p
);
const IconEye = (p) => makeIcon(
  <>
    <path d="M2 12s3-7 10-7 10 7 10 7-3 7-10 7-10-7-10-7z"/>
    <circle cx="12" cy="12" r="3"/>
  </>, p
);
const IconArrowUp = (p) => makeIcon(<><path d="M12 19V5M5 12l7-7 7 7"/></>, p);
const IconArrowDown = (p) => makeIcon(<><path d="M12 5v14M19 12l-7 7-7-7"/></>, p);
const IconTrendUp = (p) => makeIcon(<><path d="M3 17l6-6 4 4 8-8M15 7h6v6"/></>, p);
const IconChevronRight = (p) => makeIcon(<><path d="M9 6l6 6-6 6"/></>, p);
const IconTarget = (p) => makeIcon(
  <>
    <circle cx="12" cy="12" r="9"/>
    <circle cx="12" cy="12" r="5"/>
    <circle cx="12" cy="12" r="1.5" fill="currentColor" stroke="none"/>
  </>, p
);

Object.assign(window, {
  IconBenefit, IconFGTS, IconCLT, IconScore, IconParcela,
  IconHome, IconChart, IconWallet, IconUser, IconPlus, IconBell, IconEye,
  IconArrowUp, IconArrowDown, IconTrendUp, IconChevronRight, IconTarget,
});
