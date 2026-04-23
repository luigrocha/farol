// FAROL logo concepts — 4 marks + wordmark

const FAROL_NAVY = '#1B3A5C';
const FAROL_BEAM = '#F5A623';

// Wordmark typeset in Inter. Tight tracking, heavy weight.
function FarolWordmark({ color = FAROL_NAVY, size = 44 }) {
  return (
    <span style={{
      fontFamily: 'Inter, system-ui, sans-serif',
      fontWeight: 800,
      fontSize: size,
      letterSpacing: -size * 0.035,
      color,
      lineHeight: 1,
    }}>FAROL</span>
  );
}

// ─────────────────────────────────────────────────────────────
// CONCEPT A — "The Beam"
// Vertical stroke + 45° beam radiating top-right. Beam = upward arrow.
// ─────────────────────────────────────────────────────────────
function LogoA({ size = 64, tower = FAROL_NAVY, beam = FAROL_BEAM }) {
  return (
    <svg width={size} height={size} viewBox="0 0 64 64" fill="none">
      {/* tower */}
      <rect x="10" y="14" width="7" height="44" rx="1" fill={tower}/>
      <rect x="7" y="54" width="13" height="6" rx="1" fill={tower}/>
      {/* beam rays radiating from top of tower (45° upper-right) */}
      <path d="M17 18 L38 18" stroke={beam} strokeWidth="4" strokeLinecap="round"/>
      <path d="M17 18 L33 8" stroke={beam} strokeWidth="4" strokeLinecap="round"/>
      <path d="M17 18 L52 18" stroke={beam} strokeWidth="4" strokeLinecap="round" opacity="0.55"/>
      <path d="M17 18 L46 2" stroke={beam} strokeWidth="4" strokeLinecap="round" opacity="0.55"/>
    </svg>
  );
}

// ─────────────────────────────────────────────────────────────
// CONCEPT B — "The Lens"
// Fresnel lens from above: concentric arcs + bright center.
// ─────────────────────────────────────────────────────────────
function LogoB({ size = 64, ring = FAROL_NAVY, core = FAROL_BEAM }) {
  return (
    <svg width={size} height={size} viewBox="0 0 64 64" fill="none">
      <circle cx="32" cy="32" r="28" stroke={ring} strokeWidth="3" fill="none"/>
      <circle cx="32" cy="32" r="20" stroke={ring} strokeWidth="3" fill="none" opacity="0.75"/>
      <circle cx="32" cy="32" r="12" stroke={ring} strokeWidth="3" fill="none" opacity="0.5"/>
      <circle cx="32" cy="32" r="5" fill={core}/>
    </svg>
  );
}

// ─────────────────────────────────────────────────────────────
// CONCEPT C — "The Path"
// Pill/teardrop beacon + single light ray line. Echoes a map pin.
// ─────────────────────────────────────────────────────────────
function LogoC({ size = 64, body = FAROL_NAVY, ray = FAROL_BEAM }) {
  return (
    <svg width={size} height={size} viewBox="0 0 64 64" fill="none">
      {/* teardrop/pin */}
      <path
        d="M32 6 C42 6 50 14 50 24 C50 36 32 58 32 58 C32 58 14 36 14 24 C14 14 22 6 32 6 Z"
        fill={body}
      />
      {/* light ray core */}
      <circle cx="32" cy="22" r="5" fill={ray}/>
      <path d="M32 22 L32 10" stroke={ray} strokeWidth="2.5" strokeLinecap="round"/>
    </svg>
  );
}

// ─────────────────────────────────────────────────────────────
// CONCEPT D — "Wordmark only"
// FAROL with the A stylized as a lighthouse tower silhouette.
// ─────────────────────────────────────────────────────────────
function LogoD({ size = 44, color = FAROL_NAVY, accent = FAROL_BEAM }) {
  // size is the cap height; layout is hand-tuned
  const s = size;
  const bar = s * 0.18;
  return (
    <div style={{
      display: 'inline-flex', alignItems: 'flex-end', gap: s * 0.04,
      fontFamily: 'Inter, system-ui, sans-serif',
      fontWeight: 800, fontSize: s, color, letterSpacing: -s * 0.035,
      lineHeight: 1,
    }}>
      <span>F</span>
      {/* stylized A: lighthouse silhouette */}
      <svg width={s * 0.82} height={s * 1.02} viewBox="0 0 82 102" style={{ marginBottom: -s * 0.02 }}>
        {/* tower body (trapezoid) */}
        <path d="M34 22 L48 22 L58 94 L24 94 Z" fill={color}/>
        {/* crossbar (A middle) */}
        <rect x="30" y="64" width="22" height={bar * 6} fill={color}/>
        {/* beam at top */}
        <circle cx="41" cy="14" r="8" fill={accent}/>
        <path d="M41 14 L41 2" stroke={accent} strokeWidth="4" strokeLinecap="round"/>
      </svg>
      <span>R</span>
      <span>O</span>
      <span>L</span>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────
// Primary lockups (icon + wordmark)
// ─────────────────────────────────────────────────────────────
function Lockup({ concept = 'A', color = FAROL_NAVY, accent = FAROL_BEAM, size = 44 }) {
  const iconSize = size * 1.3;
  const gap = size * 0.32;
  const logos = {
    A: <LogoA size={iconSize} tower={color} beam={accent}/>,
    B: <LogoB size={iconSize} ring={color} core={accent}/>,
    C: <LogoC size={iconSize} body={color} ray={accent}/>,
  };
  if (concept === 'D') {
    return <LogoD size={size} color={color} accent={accent}/>;
  }
  return (
    <div style={{ display: 'inline-flex', alignItems: 'center', gap }}>
      {logos[concept]}
      <FarolWordmark color={color} size={size}/>
    </div>
  );
}

Object.assign(window, {
  FAROL_NAVY, FAROL_BEAM,
  FarolWordmark, LogoA, LogoB, LogoC, LogoD, Lockup,
});
