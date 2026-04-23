// Farol — shared tokens + primitives
// Brand: Farol Navy #1B3A5C · Farol Beam #F5A623 · Farol Tide #1A7A4A · Farol Coral #E84855
// Tagline: "Clareza para cada real."

const S = {
  // Surface hierarchy (warm off-white to match Farol Fog)
  surface:        '#F0EEE9',  // Level 0 — Farol paper
  surfaceLow:     '#F3F4F6',  // Level 1 — Farol Fog
  surfaceLowest:  '#FFFFFF',  // Level 2 — cards
  surfaceDim:     '#E7E4DE',  // pill inactive
  surfaceBright:  '#FFFFFF',

  // Text
  onSurface:      '#1B2332',
  onSurfaceMuted: '#374151',  // Farol Slate
  onSurfaceSoft:  '#6B7280',
  onSurfaceFaint: '#9CA3AF',

  // Brand — Farol Navy
  primary:           '#1B3A5C',  // Farol Navy
  primaryContainer:  '#244A72',  // elevated navy
  primaryDeep:       '#0D2238',  // Farol Dusk end
  onPrimary:         '#FFFFFF',

  // Beam (primary accent — amber direction)
  secondary:         '#F5A623',  // Farol Beam
  secondaryFixed:    '#FCD37D',  // light beam
  secondaryContainer:'#FDF1DB',  // beam tint

  // Tide (growth / success)
  tertiary:          '#1A7A4A',  // Farol Tide
  tertiaryFixed:     '#7FCF9E',  // light tide

  // Signals (Farol Coral for error)
  error:             '#E84855',  // Farol Coral
  warn:              '#F5A623',
  errorSoft:         '#FCE5E7',

  // Categorical chart colors
  catA: '#1A7A4A',  // tide
  catB: '#F5A623',  // beam
  catC: '#1B3A5C',  // navy
  catD: '#8FA3B8',  // slate

  // Strokes (ghost)
  ghost: 'rgba(27,58,92,0.10)',

  // Shadow
  ambient: '0 12px 40px rgba(27,58,92,0.08)',
};

// Fonts (loaded globally via <link> in index)
const MANROPE = '"Manrope", Inter, system-ui, sans-serif';
const INTER   = 'Inter, system-ui, sans-serif';

// ─────────────────────────────────────────────────────────────
// BRL formatter — split int/dec so we can style
// ─────────────────────────────────────────────────────────────
function fmtBRL(value, { dec = 2 } = {}) {
  const neg = value < 0;
  const [i, d] = Math.abs(value).toFixed(dec).replace('.', ',').split(',');
  const ii = i.replace(/\B(?=(\d{3})+(?!\d))/g, '.');
  return { neg, int: ii, dec: d };
}

function BRLBig({ value, size = 44, color = S.onSurface, weight = 800, font = MANROPE }) {
  const { neg, int, dec } = fmtBRL(value);
  return (
    <span style={{
      fontFamily: font, color, fontWeight: weight,
      fontSize: size, letterSpacing: -size * 0.028, lineHeight: 1,
      fontVariantNumeric: 'tabular-nums',
      display: 'inline-flex', alignItems: 'baseline', gap: size * 0.1,
    }}>
      <span style={{ fontSize: size * 0.48, fontWeight: 500, letterSpacing: 0 }}>
        {neg ? '−' : ''}R$
      </span>
      <span>
        {int}
        <span style={{ fontSize: size * 0.56, opacity: 0.85 }}>,{dec}</span>
      </span>
    </span>
  );
}

function BRLSmall({ value, size = 14, color = S.onSurface, weight = 600 }) {
  const { neg, int, dec } = fmtBRL(value);
  return (
    <span style={{
      fontFamily: INTER, color, fontWeight: weight,
      fontSize: size, fontVariantNumeric: 'tabular-nums',
      letterSpacing: -0.1,
    }}>
      {neg ? '−' : ''}R$ {int},{dec}
    </span>
  );
}

// ─────────────────────────────────────────────────────────────
// Screen shell — a phone without a frame, fixed height
// ─────────────────────────────────────────────────────────────
function Screen({ children, bg = S.surface, tab = 'Inicio' }) {
  return (
    <div style={{
      width: 390, height: 844, background: bg,
      borderRadius: 38, overflow: 'hidden', position: 'relative',
      fontFamily: INTER, color: S.onSurface,
      boxShadow: '0 24px 60px rgba(0,0,0,0.14), 0 0 0 1px rgba(0,0,0,0.05)',
      display: 'flex', flexDirection: 'column',
    }}>
      {/* status bar */}
      <div style={{
        height: 44, paddingTop: 14, display: 'flex',
        justifyContent: 'space-between', alignItems: 'center', padding: '14px 26px 0',
        fontFamily: MANROPE, fontSize: 15, fontWeight: 700, color: S.onSurface,
        flexShrink: 0,
      }}>
        <span>9:41</span>
        <div style={{ display: 'flex', gap: 5, alignItems: 'center' }}>
          <SignalIcon/><WifiIcon/><BatteryIcon/>
        </div>
      </div>
      <div style={{ flex: 1, overflow: 'hidden', position: 'relative' }}>
        {children}
      </div>
      <BottomNav active={tab}/>
    </div>
  );
}

function SignalIcon() {
  return (
    <svg width="16" height="10" viewBox="0 0 16 10" fill="none">
      <rect x="0" y="6" width="3" height="4" rx="0.5" fill={S.onSurface}/>
      <rect x="4.5" y="4" width="3" height="6" rx="0.5" fill={S.onSurface}/>
      <rect x="9" y="2" width="3" height="8" rx="0.5" fill={S.onSurface}/>
      <rect x="13.5" y="0" width="3" height="10" rx="0.5" fill={S.onSurface}/>
    </svg>
  );
}
function WifiIcon() {
  return (
    <svg width="14" height="10" viewBox="0 0 14 10" fill="none">
      <path d="M7 8.5a1 1 0 100-2 1 1 0 000 2zM1 3.5C2.7 2 4.8 1 7 1s4.3 1 6 2.5l-1.2 1.2c-1.3-1.2-3-1.9-4.8-1.9S3.5 3.5 2.2 4.7L1 3.5zm2.4 2.4C4.4 5 5.6 4.5 7 4.5s2.6.5 3.6 1.4L9.4 7.1c-.7-.6-1.5-1-2.4-1s-1.7.4-2.4 1L3.4 5.9z" fill={S.onSurface}/>
    </svg>
  );
}
function BatteryIcon() {
  return (
    <svg width="24" height="11" viewBox="0 0 24 11" fill="none">
      <rect x="0.5" y="0.5" width="21" height="10" rx="2.5" stroke={S.onSurface} strokeOpacity="0.35"/>
      <rect x="2" y="2" width="18" height="7" rx="1.2" fill={S.onSurface}/>
      <rect x="22.5" y="3.5" width="1" height="4" rx="0.5" fill={S.onSurface} fillOpacity="0.35"/>
    </svg>
  );
}

// ─────────────────────────────────────────────────────────────
// Bottom nav — glassmorphic, 5 items
// ─────────────────────────────────────────────────────────────
function BottomNav({ active }) {
  const items = [
    { id: 'Inicio',    Icon: NavHome },
    { id: 'Invertir',  Icon: NavInvest },
    { id: 'Lanzar',    Icon: NavPlus, fab: true },
    { id: 'Tarjetas',  Icon: NavCard },
    { id: 'Ajustes',   Icon: NavSettings },
  ];
  return (
    <div style={{
      position: 'relative', flexShrink: 0,
      background: 'rgba(255,255,255,0.85)',
      backdropFilter: 'blur(16px) saturate(180%)',
      WebkitBackdropFilter: 'blur(16px) saturate(180%)',
      padding: '10px 18px 24px',
      display: 'flex', justifyContent: 'space-around', alignItems: 'center',
      borderTop: '0.5px solid rgba(26,28,30,0.05)',
    }}>
      {items.map(it => {
        const isActive = it.id === active;
        if (it.fab) {
          return (
            <button key={it.id} style={{
              width: 52, height: 52, borderRadius: 26,
              background: `linear-gradient(135deg, ${S.primaryContainer}, ${S.primary})`,
              border: 'none', cursor: 'pointer', marginTop: -18,
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: '0 12px 24px rgba(0,36,68,0.28)',
            }}>
              <it.Icon size={22} color="#fff"/>
            </button>
          );
        }
        return (
          <button key={it.id} style={{
            background: 'transparent', border: 'none', cursor: 'pointer',
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4,
            minWidth: 54, padding: 4,
          }}>
            <it.Icon size={22} color={isActive ? S.onSurface : S.onSurfaceFaint}/>
            <span style={{
              fontSize: 10, fontWeight: 600,
              letterSpacing: 0.6, textTransform: 'uppercase',
              color: isActive ? S.onSurface : S.onSurfaceFaint,
            }}>{it.id}</span>
          </button>
        );
      })}
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Shared icons — 2pt stroke, open-path
// ─────────────────────────────────────────────────────────────
const makeIcon = (paths) => ({ size = 20, color = S.onSurface, strokeWidth = 1.75 }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none"
    stroke={color} strokeWidth={strokeWidth} strokeLinecap="round" strokeLinejoin="round">
    {paths}
  </svg>
);

const NavHome = makeIcon(<><path d="M3 11l9-8 9 8v10a1 1 0 01-1 1h-4v-7H8v7H4a1 1 0 01-1-1V11z"/></>);
const NavInvest = makeIcon(<><path d="M3 17l6-6 4 4 8-8M15 7h6v6"/></>);
const NavPlus = makeIcon(<><path d="M12 5v14M5 12h14"/></>);
const NavCard = makeIcon(<><rect x="3" y="6" width="18" height="13" rx="2"/><path d="M3 10h18M6 15h4"/></>);
const NavSettings = makeIcon(<><path d="M3 6h12M3 12h18M3 18h8"/><circle cx="18" cy="6" r="2.5"/><circle cx="16" cy="18" r="2.5"/></>);

const IcBell = makeIcon(<><path d="M6 9a6 6 0 0112 0c0 5 2 6 2 6H4s2-1 2-6z"/><path d="M10 19a2 2 0 004 0"/></>);
const IcChevL = makeIcon(<><path d="M15 6l-6 6 6 6"/></>);
const IcChevR = makeIcon(<><path d="M9 6l6 6-6 6"/></>);
const IcSearch = makeIcon(<><circle cx="11" cy="11" r="7"/><path d="M20 20l-3.5-3.5"/></>);
const IcCal = makeIcon(<><rect x="3" y="5" width="18" height="16" rx="2"/><path d="M3 10h18M8 3v4M16 3v4"/></>);
const IcPlus = makeIcon(<><path d="M12 5v14M5 12h14"/></>);
const IcGlobe = makeIcon(<><circle cx="12" cy="12" r="9"/><path d="M3 12h18M12 3c3 3 3 15 0 18M12 3c-3 3-3 15 0 18"/></>);
const IcGear = makeIcon(<><circle cx="12" cy="12" r="3"/><path d="M12 2v3M12 19v3M2 12h3M19 12h3M5 5l2 2M17 17l2 2M5 19l2-2M17 7l2-2"/></>);
const IcDownload = makeIcon(<><path d="M12 4v12M7 11l5 5 5-5M4 20h16"/></>);
const IcShield = makeIcon(<><path d="M12 3l8 3v6c0 5-4 9-8 10-4-1-8-5-8-10V6l8-3z"/></>);
const IcCheck = makeIcon(<><path d="M5 12l5 5L20 7"/></>);
const IcChatBubble = makeIcon(<><path d="M21 12a8 8 0 11-3-6.2V9"/><path d="M21 4v5h-5"/></>);
const IcHeadset = makeIcon(<><path d="M4 13V11a8 8 0 0116 0v2"/><rect x="3" y="13" width="4" height="7" rx="1.5"/><rect x="17" y="13" width="4" height="7" rx="1.5"/></>);
const IcLogOut = makeIcon(<><path d="M10 4H5a1 1 0 00-1 1v14a1 1 0 001 1h5M15 8l4 4-4 4M9 12h10"/></>);
const IcSun = makeIcon(<><circle cx="12" cy="12" r="4"/><path d="M12 2v2M12 20v2M2 12h2M20 12h2M5 5l1.5 1.5M17.5 17.5L19 19M5 19l1.5-1.5M17.5 6.5L19 5"/></>);
const IcMoon = makeIcon(<><path d="M20 14A8 8 0 119 3a7 7 0 0011 11z"/></>);
const IcTrendUp = makeIcon(<><path d="M3 17l6-6 4 4 8-8M15 7h6v6"/></>);
const IcTrendDown = makeIcon(<><path d="M3 7l6 6 4-4 8 8M15 17h6v-6"/></>);
const IcWallet = makeIcon(<><rect x="3" y="7" width="18" height="12" rx="2"/><path d="M3 10h18"/><circle cx="16.5" cy="13.5" r="1" fill="currentColor" stroke="none"/></>);
const IcFork = makeIcon(<><path d="M7 3v8a2 2 0 002 2h0a2 2 0 002-2V3M9 13v8M15 3v4a3 3 0 003 3v11"/></>);
const IcCar = makeIcon(<><path d="M3 14l2-5a2 2 0 012-1h10a2 2 0 012 1l2 5v4a1 1 0 01-1 1h-2a1 1 0 01-1-1v-1H7v1a1 1 0 01-1 1H4a1 1 0 01-1-1v-4z"/><circle cx="7" cy="15" r="1" fill="currentColor"/><circle cx="17" cy="15" r="1" fill="currentColor"/></>);
const IcBag = makeIcon(<><path d="M5 8h14l-1 12a1 1 0 01-1 1H7a1 1 0 01-1-1L5 8zM9 8V6a3 3 0 016 0v2"/></>);
const IcHome = makeIcon(<><path d="M3 11l9-8 9 8v10a1 1 0 01-1 1h-4v-7H8v7H4a1 1 0 01-1-1V11z"/></>);
const IcLaptop = makeIcon(<><rect x="4" y="5" width="16" height="11" rx="1.5"/><path d="M2 20h20"/></>);
const IcPlane = makeIcon(<><path d="M3 12l6-2 5-6 2 1-3 6 6 2-1 2-6-1-3 5-2-1 1-5-4-1z"/></>);
const IcSofa = makeIcon(<><path d="M4 10V8a2 2 0 114 0v3M20 10V8a2 2 0 10-4 0v3M4 11h16a2 2 0 012 2v4h-2v2h-2v-2H6v2H4v-2H2v-4a2 2 0 012-2z"/></>);
const IcBuilding = makeIcon(<><path d="M4 21V5a1 1 0 011-1h6a1 1 0 011 1v16M12 21V10a1 1 0 011-1h6a1 1 0 011 1v11"/><path d="M3 21h18M7 8h2M7 12h2M7 16h2M15 13h2M15 17h2"/></>);
const IcSparkle = makeIcon(<><path d="M12 3v4M12 17v4M3 12h4M17 12h4M5.6 5.6l2.8 2.8M15.6 15.6l2.8 2.8M5.6 18.4l2.8-2.8M15.6 8.4l2.8-2.8"/></>);
const IcAlert = makeIcon(<><path d="M12 3l10 17H2L12 3z"/><path d="M12 10v5M12 18v.01" stroke="currentColor"/></>);
const IcBulb = makeIcon(<><path d="M9 18h6M10 22h4M12 2a7 7 0 00-5 11.9c1 1.1 1.5 2.1 1.5 3.1h7c0-1 .5-2 1.5-3.1A7 7 0 0012 2z"/></>);
const IcDoc = makeIcon(<><path d="M6 3h9l4 4v13a1 1 0 01-1 1H6a1 1 0 01-1-1V4a1 1 0 011-1z"/><path d="M15 3v4h4M8 13h8M8 17h5"/></>);
const IcDots = makeIcon(<><circle cx="5" cy="12" r="1.5" fill="currentColor"/><circle cx="12" cy="12" r="1.5" fill="currentColor"/><circle cx="19" cy="12" r="1.5" fill="currentColor"/></>);
const IcArrowBack = makeIcon(<><path d="M20 12H4M10 18l-6-6 6-6"/></>);
const IcCup = makeIcon(<><path d="M5 6h12v5a6 6 0 11-12 0V6zM17 8h2a2 2 0 110 4h-2M4 21h14"/></>);

Object.assign(window, {
  S, MANROPE, INTER,
  fmtBRL, BRLBig, BRLSmall,
  Screen, BottomNav,
  IcBell, IcChevL, IcChevR, IcSearch, IcCal, IcPlus, IcGlobe, IcGear,
  IcDownload, IcShield, IcCheck, IcChatBubble, IcHeadset, IcLogOut,
  IcSun, IcMoon, IcTrendUp, IcTrendDown, IcWallet, IcFork, IcCar, IcBag,
  IcHome, IcLaptop, IcPlane, IcSofa, IcBuilding, IcSparkle, IcAlert,
  IcBulb, IcDoc, IcDots, IcArrowBack, IcCup,
});
