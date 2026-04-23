// FAROL prototype screens — onboarding + home dashboard + transactions
// Flutter-inspired, iOS-framed.

const F = {
  navy: '#1B3A5C',
  navyDeep: '#0D2238',
  beam: '#F5A623',
  tide: '#1A7A4A',
  coral: '#E84855',
  fog: '#F3F4F6',
  slate: '#374151',
  slate60: '#6B7280',
  slate30: '#9CA3AF',
  line: '#E5E7EB',
};

// Currency formatter: "R$" small + value big; never mixes weights within amount.
function BRL({ value, size = 24, color = F.navy, sign = false, sub = false }) {
  const [int, dec] = value.toFixed(2).replace('.', ',').split(',');
  const intFmt = int.replace(/\B(?=(\d{3})+(?!\d))/g, '.');
  const neg = value < 0;
  return (
    <span style={{
      fontFamily: 'Inter, system-ui', fontVariantNumeric: 'tabular-nums',
      color, display: 'inline-flex', alignItems: 'baseline', gap: size * 0.12,
    }}>
      <span style={{ fontSize: size * 0.54, fontWeight: 400, letterSpacing: 0.2, opacity: 0.75 }}>
        {sign ? (neg ? '−' : '+') : ''}R$
      </span>
      <span style={{ fontSize: size, fontWeight: 700, letterSpacing: -0.3 }}>
        {intFmt.replace('-', '')}
        <span style={{ fontSize: size * 0.6, fontWeight: 600 }}>,{dec}</span>
      </span>
    </span>
  );
}

// ─────────────────────────────────────────────────────────────
// ONBOARDING — 3 steps, with a standalone welcome
// ─────────────────────────────────────────────────────────────
function Onboarding({ onFinish, logoConcept = 'A' }) {
  const [step, setStep] = React.useState(0);

  const Dots = () => (
    <div style={{ display: 'flex', gap: 6, justifyContent: 'center' }}>
      {[0, 1, 2].map(i => (
        <div key={i} style={{
          width: i === step ? 22 : 6, height: 6, borderRadius: 3,
          background: i === step ? F.beam : 'rgba(255,255,255,0.3)',
          transition: 'width 240ms ease',
        }}/>
      ))}
    </div>
  );

  const Continue = ({ label = 'Continuar', onClick }) => (
    <button onClick={onClick} style={{
      width: '100%', height: 56, borderRadius: 16,
      background: F.beam, color: F.navyDeep, border: 'none',
      fontFamily: 'Inter', fontSize: 17, fontWeight: 600, letterSpacing: -0.2,
      cursor: 'pointer', boxShadow: '0 4px 14px rgba(245,166,35,0.35)',
    }}>{label}</button>
  );

  const slides = [
    {
      kicker: 'Bem-vindo ao Farol',
      title: 'Seu dinheiro\nno rumo certo.',
      body: 'Um guia claro para cada real — do salário ao primeiro investimento.',
      art: <BeamArt concept={logoConcept}/>,
    },
    {
      kicker: 'Clareza',
      title: 'Tudo que entra\ne sai, num só lugar.',
      body: 'Conectamos sua conta, classificamos tudo. Sem planilha, sem estresse.',
      art: <ClarityArt/>,
    },
    {
      kicker: 'Direção',
      title: 'Metas que\nfazem sentido pra você.',
      body: 'Reserva de emergência, viagem, FGTS. O Farol ilumina o próximo passo.',
      art: <CompassArt/>,
    },
  ];

  const s = slides[step];

  return (
    <div style={{
      height: '100%',
      background: `linear-gradient(135deg, ${F.navy} 0%, ${F.navyDeep} 100%)`,
      display: 'flex', flexDirection: 'column',
      color: '#fff', position: 'relative', overflow: 'hidden',
    }}>
      {/* ambient beam glow */}
      <div style={{
        position: 'absolute', top: -120, right: -80, width: 360, height: 360,
        borderRadius: '50%',
        background: 'radial-gradient(circle, rgba(245,166,35,0.25) 0%, transparent 60%)',
        pointerEvents: 'none',
      }}/>

      {/* top: skip */}
      <div style={{ paddingTop: 64, paddingRight: 20, display: 'flex', justifyContent: 'flex-end' }}>
        <button onClick={onFinish} style={{
          background: 'transparent', border: 'none', color: 'rgba(255,255,255,0.7)',
          fontFamily: 'Inter', fontSize: 15, fontWeight: 500, cursor: 'pointer',
        }}>Pular</button>
      </div>

      {/* art */}
      <div style={{
        flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center',
        padding: '20px 32px',
      }}>
        <div key={step} style={{ animation: 'farolFade 400ms ease' }}>
          {s.art}
        </div>
      </div>

      {/* copy */}
      <div style={{ padding: '0 32px 24px' }}>
        <div style={{
          fontFamily: 'Inter', fontSize: 11, fontWeight: 600,
          letterSpacing: 1.5, textTransform: 'uppercase',
          color: F.beam, marginBottom: 12,
        }}>{s.kicker}</div>
        <div style={{
          fontFamily: 'Inter', fontSize: 32, fontWeight: 700,
          lineHeight: 1.12, letterSpacing: -0.8,
          whiteSpace: 'pre-line', marginBottom: 16,
        }}>{s.title}</div>
        <div style={{
          fontFamily: 'Inter', fontSize: 15, fontWeight: 400,
          lineHeight: 1.5, color: 'rgba(255,255,255,0.75)',
          maxWidth: 320,
        }}>{s.body}</div>
      </div>

      {/* footer: dots + cta */}
      <div style={{ padding: '0 24px 48px', display: 'flex', flexDirection: 'column', gap: 24 }}>
        <Dots/>
        <Continue
          label={step === 2 ? 'Começar' : 'Continuar'}
          onClick={() => step === 2 ? onFinish() : setStep(step + 1)}
        />
      </div>
    </div>
  );
}

// Illustration: beam + tower (uses chosen concept)
function BeamArt({ concept = 'A' }) {
  return (
    <div style={{
      width: 240, height: 240, borderRadius: '50%',
      background: 'rgba(255,255,255,0.04)',
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      border: '1px solid rgba(255,255,255,0.08)',
      position: 'relative',
    }}>
      <div style={{
        position: 'absolute', inset: 20, borderRadius: '50%',
        border: '1px solid rgba(255,255,255,0.06)',
      }}/>
      {concept === 'A' && <LogoA size={140} tower="#fff" beam={F.beam}/>}
      {concept === 'B' && <LogoB size={140} ring="#fff" core={F.beam}/>}
      {concept === 'C' && <LogoC size={140} body="#fff" ray={F.beam}/>}
      {concept === 'D' && <LogoA size={140} tower="#fff" beam={F.beam}/>}
    </div>
  );
}

// Illustration: categorized chips
function ClarityArt() {
  const chips = [
    { l: 'Mercado', c: F.beam, t: 'R$ 840' },
    { l: 'Transporte', c: '#fff', t: 'R$ 312' },
    { l: 'Lazer', c: F.beam, t: 'R$ 215' },
    { l: 'Moradia', c: '#fff', t: 'R$ 2.400' },
    { l: 'Saúde', c: F.beam, t: 'R$ 180' },
  ];
  return (
    <div style={{ display: 'flex', flexDirection: 'column', gap: 10, width: 260 }}>
      {chips.map((ch, i) => (
        <div key={i} style={{
          display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          background: 'rgba(255,255,255,0.06)', backdropFilter: 'blur(8px)',
          padding: '12px 16px', borderRadius: 12,
          border: `1px solid rgba(255,255,255,0.08)`,
          transform: `translateX(${(i % 2 === 0 ? -1 : 1) * 10}px)`,
        }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{ width: 8, height: 8, borderRadius: 4, background: ch.c }}/>
            <span style={{ fontFamily: 'Inter', fontSize: 14, fontWeight: 500 }}>{ch.l}</span>
          </div>
          <span style={{ fontFamily: 'Inter', fontSize: 14, fontWeight: 600,
            fontVariantNumeric: 'tabular-nums', color: 'rgba(255,255,255,0.8)' }}>{ch.t}</span>
        </div>
      ))}
    </div>
  );
}

// Illustration: compass/target
function CompassArt() {
  return (
    <svg width="240" height="240" viewBox="0 0 240 240" fill="none">
      <circle cx="120" cy="120" r="100" stroke="rgba(255,255,255,0.12)" strokeWidth="1"/>
      <circle cx="120" cy="120" r="70" stroke="rgba(255,255,255,0.18)" strokeWidth="1"/>
      <circle cx="120" cy="120" r="40" stroke="rgba(255,255,255,0.25)" strokeWidth="1"/>
      {/* ticks */}
      {Array.from({ length: 12 }).map((_, i) => {
        const a = (i * 30) * Math.PI / 180;
        const x1 = 120 + Math.cos(a) * 100, y1 = 120 + Math.sin(a) * 100;
        const x2 = 120 + Math.cos(a) * 108, y2 = 120 + Math.sin(a) * 108;
        return <line key={i} x1={x1} y1={y1} x2={x2} y2={y2} stroke="rgba(255,255,255,0.3)" strokeWidth="2"/>;
      })}
      {/* needle */}
      <path d="M120 50 L128 120 L120 130 L112 120 Z" fill={F.beam}/>
      <path d="M120 190 L128 120 L120 110 L112 120 Z" fill="rgba(255,255,255,0.5)"/>
      <circle cx="120" cy="120" r="6" fill="#fff"/>
      <circle cx="120" cy="120" r="2" fill={F.navyDeep}/>
    </svg>
  );
}

// ─────────────────────────────────────────────────────────────
// HOME DASHBOARD
// ─────────────────────────────────────────────────────────────
function HomeDashboard({ logoConcept = 'A' }) {
  const [tab, setTab] = React.useState('home');
  const [hidden, setHidden] = React.useState(false);

  return (
    <div style={{
      height: '100%', background: F.fog, display: 'flex', flexDirection: 'column',
      fontFamily: 'Inter, system-ui',
    }}>
      {/* status bar absolute handled by frame. Push content down by 54. */}
      <div style={{ height: 54, flexShrink: 0 }}/>

      {/* Scrollable content */}
      <div style={{ flex: 1, overflowY: 'auto', paddingBottom: 100 }}>
        <TopBar logoConcept={logoConcept}/>
        <BalanceCard hidden={hidden} onToggle={() => setHidden(h => !h)}/>
        <QuickActions/>
        <FarolScore/>
        <BudgetCategories/>
        <TransactionsList/>
        <InvestmentTeaser/>
      </div>

      <BottomNav tab={tab} setTab={setTab}/>
    </div>
  );
}

function TopBar({ logoConcept }) {
  return (
    <div style={{
      display: 'flex', alignItems: 'center', justifyContent: 'space-between',
      padding: '8px 20px 16px',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        {logoConcept === 'A' && <LogoA size={28}/>}
        {logoConcept === 'B' && <LogoB size={28}/>}
        {logoConcept === 'C' && <LogoC size={28}/>}
        {logoConcept === 'D' && <LogoA size={28}/>}
        <div>
          <div style={{ fontSize: 11, color: F.slate60, fontWeight: 500, letterSpacing: 0.3 }}>BOA TARDE</div>
          <div style={{ fontSize: 17, color: F.navy, fontWeight: 600, letterSpacing: -0.3, marginTop: 1 }}>Mariana</div>
        </div>
      </div>
      <div style={{
        width: 40, height: 40, borderRadius: 20,
        background: '#fff', display: 'flex', alignItems: 'center', justifyContent: 'center',
        boxShadow: '0 1px 2px rgba(0,0,0,0.04)',
        position: 'relative',
      }}>
        <IconBell color={F.slate}/>
        <div style={{
          position: 'absolute', top: 9, right: 10,
          width: 8, height: 8, borderRadius: 4, background: F.coral,
          border: '2px solid #fff',
        }}/>
      </div>
    </div>
  );
}

function BalanceCard({ hidden, onToggle }) {
  return (
    <div style={{
      margin: '0 16px 16px',
      background: `linear-gradient(135deg, ${F.navy} 0%, ${F.navyDeep} 100%)`,
      borderRadius: 20, padding: '20px 20px 24px', color: '#fff',
      position: 'relative', overflow: 'hidden',
    }}>
      {/* beam accent */}
      <div style={{
        position: 'absolute', top: -40, right: -40, width: 160, height: 160,
        borderRadius: '50%',
        background: 'radial-gradient(circle, rgba(245,166,35,0.22) 0%, transparent 65%)',
      }}/>

      <div style={{
        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
        marginBottom: 6,
      }}>
        <span style={{ fontSize: 13, color: 'rgba(255,255,255,0.7)', fontWeight: 500, letterSpacing: 0.1 }}>
          Saldo total
        </span>
        <button onClick={onToggle} style={{
          background: 'rgba(255,255,255,0.1)', border: 'none', borderRadius: 99,
          padding: '6px 10px', display: 'flex', alignItems: 'center', gap: 6,
          color: 'rgba(255,255,255,0.8)', cursor: 'pointer',
        }}>
          <IconEye size={14} color="rgba(255,255,255,0.8)"/>
          <span style={{ fontSize: 11, fontWeight: 500 }}>{hidden ? 'Mostrar' : 'Ocultar'}</span>
        </button>
      </div>

      <div style={{ marginBottom: 16 }}>
        {hidden ? (
          <div style={{ fontSize: 34, fontWeight: 700, letterSpacing: 4 }}>••••••</div>
        ) : (
          <BRL value={18432.50} size={34} color="#fff"/>
        )}
      </div>

      <div style={{ display: 'flex', gap: 20, alignItems: 'center' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <div style={{
            width: 22, height: 22, borderRadius: 11,
            background: 'rgba(26,122,74,0.35)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <IconArrowDown size={13} color="#7FD1A1"/>
          </div>
          <div>
            <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.6)' }}>Entradas</div>
            <div style={{ fontSize: 13, fontWeight: 600 }}>R$ 8.420</div>
          </div>
        </div>
        <div style={{ width: 1, height: 28, background: 'rgba(255,255,255,0.1)' }}/>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <div style={{
            width: 22, height: 22, borderRadius: 11,
            background: 'rgba(232,72,85,0.3)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>
            <IconArrowUp size={13} color="#F5A0A6"/>
          </div>
          <div>
            <div style={{ fontSize: 11, color: 'rgba(255,255,255,0.6)' }}>Saídas</div>
            <div style={{ fontSize: 13, fontWeight: 600 }}>R$ 5.218</div>
          </div>
        </div>
      </div>
    </div>
  );
}

function QuickActions() {
  const items = [
    { label: 'Transferir', icon: <IconArrowUp size={20} color={F.navy}/> },
    { label: 'Pagar', icon: <IconParcela size={20} color={F.navy}/> },
    { label: 'Investir', icon: <IconTrendUp size={20} color={F.navy}/> },
    { label: 'Metas', icon: <IconTarget size={20} color={F.navy}/> },
  ];
  return (
    <div style={{
      background: '#fff', margin: '0 16px 16px', borderRadius: 16,
      padding: '14px 8px', display: 'flex', justifyContent: 'space-around',
    }}>
      {items.map(it => (
        <button key={it.label} style={{
          background: 'transparent', border: 'none', cursor: 'pointer',
          display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6,
          padding: '4px 8px',
        }}>
          <div style={{
            width: 44, height: 44, borderRadius: 12,
            background: F.fog,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
          }}>{it.icon}</div>
          <span style={{ fontSize: 11, color: F.slate, fontWeight: 500 }}>{it.label}</span>
        </button>
      ))}
    </div>
  );
}

function FarolScore() {
  const score = 720;
  const max = 1000;
  const pct = score / max;
  const R = 42, stroke = 7;
  const C = 2 * Math.PI * R;
  const half = C / 2; // semicircle
  const arcLen = half * pct;

  return (
    <div style={{
      background: '#fff', margin: '0 16px 16px', borderRadius: 16,
      padding: 18,
    }}>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between' }}>
        <div>
          <div style={{ fontSize: 11, color: F.slate60, fontWeight: 500, letterSpacing: 0.4, textTransform: 'uppercase' }}>
            Farol Score
          </div>
          <div style={{
            fontSize: 32, fontWeight: 700, color: F.navy,
            fontVariantNumeric: 'tabular-nums', letterSpacing: -0.5,
            display: 'flex', alignItems: 'baseline', gap: 4, marginTop: 2,
          }}>
            {score}
            <span style={{ fontSize: 13, fontWeight: 500, color: F.slate60 }}>/ {max}</span>
          </div>
          <div style={{
            display: 'inline-flex', alignItems: 'center', gap: 6,
            background: 'rgba(26,122,74,0.1)', color: F.tide,
            padding: '4px 10px', borderRadius: 99, marginTop: 8,
            fontSize: 11, fontWeight: 600, letterSpacing: 0.2,
          }}>
            <IconTrendUp size={12} color={F.tide}/>
            +24 este mês
          </div>
        </div>

        {/* semicircle gauge */}
        <div style={{ position: 'relative', width: 110, height: 70 }}>
          <svg width="110" height="70" viewBox="0 0 110 70">
            <path
              d={`M 13 60 A ${R} ${R} 0 0 1 97 60`}
              stroke={F.fog} strokeWidth={stroke} fill="none" strokeLinecap="round"
            />
            <path
              d={`M 13 60 A ${R} ${R} 0 0 1 97 60`}
              stroke={F.beam} strokeWidth={stroke} fill="none" strokeLinecap="round"
              strokeDasharray={`${arcLen} ${C}`}
            />
          </svg>
          <div style={{
            position: 'absolute', bottom: 0, left: 0, right: 0,
            display: 'flex', justifyContent: 'space-between', padding: '0 6px',
            fontSize: 10, color: F.slate30,
          }}>
            <span>0</span><span>1000</span>
          </div>
          <div style={{
            position: 'absolute', top: 36, left: 0, right: 0, textAlign: 'center',
            fontSize: 11, fontWeight: 600, color: F.navy, letterSpacing: 0.2,
          }}>Bom</div>
        </div>
      </div>
    </div>
  );
}

function BudgetCategories() {
  const cats = [
    { label: 'Moradia',    spent: 2400, cap: 2500, color: F.navy },
    { label: 'Mercado',    spent: 840,  cap: 1200, color: F.tide },
    { label: 'Transporte', spent: 312,  cap: 400,  color: F.beam },
    { label: 'Lazer',      spent: 215,  cap: 300,  color: F.coral },
  ];
  return (
    <div style={{ background: '#fff', margin: '0 16px 16px', borderRadius: 16, padding: 18 }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 }}>
        <div style={{ fontSize: 17, fontWeight: 600, color: F.navy, letterSpacing: -0.3 }}>Orçamento</div>
        <div style={{ fontSize: 12, color: F.slate60 }}>Abril</div>
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
        {cats.map(c => {
          const pct = Math.min(c.spent / c.cap, 1);
          const over = c.spent / c.cap > 0.9;
          return (
            <div key={c.label}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 6 }}>
                <span style={{ fontSize: 13, color: F.slate, fontWeight: 500 }}>{c.label}</span>
                <span style={{ fontSize: 12, color: over ? F.coral : F.slate60, fontVariantNumeric: 'tabular-nums' }}>
                  R$ {c.spent.toLocaleString('pt-BR')} / {c.cap.toLocaleString('pt-BR')}
                </span>
              </div>
              <div style={{ height: 6, background: F.fog, borderRadius: 3, overflow: 'hidden' }}>
                <div style={{
                  width: `${pct * 100}%`, height: '100%',
                  background: over ? F.coral : c.color,
                  borderRadius: 3,
                  transition: 'width 600ms ease',
                }}/>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

function TransactionsList() {
  const txs = [
    { label: 'Swile — Almoço', sub: 'Alimentação • hoje, 12:34', value: -42.80, icon: <IconBenefit size={18} color={F.navy}/> },
    { label: 'Salário Abril',  sub: 'CLT • ontem',              value: +6800.00, icon: <IconCLT size={18} color={F.tide}/>, green: true },
    { label: 'Fatura Nubank',  sub: '4ª parcela de 10 • 18/04', value: -389.90, icon: <IconParcela size={18} color={F.navy}/> },
    { label: 'Uber',           sub: 'Transporte • 17/04',        value: -28.50,  icon: <IconWallet size={18} color={F.navy}/> },
  ];
  return (
    <div style={{ background: '#fff', margin: '0 16px 16px', borderRadius: 16, padding: '18px 0 6px' }}>
      <div style={{
        display: 'flex', justifyContent: 'space-between', alignItems: 'center',
        padding: '0 18px', marginBottom: 8,
      }}>
        <div style={{ fontSize: 17, fontWeight: 600, color: F.navy, letterSpacing: -0.3 }}>Movimentações</div>
        <button style={{
          background: 'none', border: 'none', color: F.navy,
          fontSize: 13, fontWeight: 500, cursor: 'pointer',
          display: 'inline-flex', alignItems: 'center', gap: 2,
        }}>
          Ver tudo
          <IconChevronRight size={14} color={F.navy}/>
        </button>
      </div>
      {txs.map((t, i) => (
        <div key={i} style={{
          display: 'flex', alignItems: 'center', gap: 12,
          padding: '10px 18px',
          borderTop: i > 0 ? `1px solid ${F.line}` : 'none',
        }}>
          <div style={{
            width: 36, height: 36, borderRadius: 10,
            background: t.green ? 'rgba(26,122,74,0.1)' : F.fog,
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            flexShrink: 0,
          }}>{t.icon}</div>
          <div style={{ flex: 1, minWidth: 0 }}>
            <div style={{ fontSize: 14, fontWeight: 500, color: F.navy, letterSpacing: -0.1 }}>{t.label}</div>
            <div style={{ fontSize: 11, color: F.slate60, marginTop: 1 }}>{t.sub}</div>
          </div>
          <div style={{ fontVariantNumeric: 'tabular-nums', textAlign: 'right' }}>
            <BRL value={t.value} size={14} color={t.green ? F.tide : F.navy} sign/>
          </div>
        </div>
      ))}
    </div>
  );
}

function InvestmentTeaser() {
  return (
    <div style={{
      margin: '0 16px 16px', borderRadius: 16,
      padding: 18, background: '#fff',
      display: 'flex', alignItems: 'center', gap: 14,
      border: `1px solid ${F.line}`,
    }}>
      <div style={{
        width: 44, height: 44, borderRadius: 12,
        background: 'rgba(245,166,35,0.15)',
        display: 'flex', alignItems: 'center', justifyContent: 'center',
        flexShrink: 0,
      }}>
        <IconFGTS size={22} color={F.beam}/>
      </div>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 13, fontWeight: 600, color: F.navy, letterSpacing: -0.1 }}>
          Você tem R$ 12.400 no FGTS
        </div>
        <div style={{ fontSize: 11, color: F.slate60, marginTop: 2 }}>
          Saque-aniversário pode render 3× mais no Tesouro
        </div>
      </div>
      <IconChevronRight size={18} color={F.slate30}/>
    </div>
  );
}

function BottomNav({ tab, setTab }) {
  const items = [
    { id: 'home', label: 'Início', icon: IconHome },
    { id: 'chart', label: 'Gastos', icon: IconChart },
    { id: 'plus', label: null, icon: IconPlus }, // FAB
    { id: 'invest', label: 'Investir', icon: IconTrendUp },
    { id: 'user', label: 'Perfil', icon: IconUser },
  ];
  return (
    <div style={{
      position: 'absolute', bottom: 0, left: 0, right: 0,
      paddingBottom: 34, // home indicator
      background: 'rgba(255,255,255,0.92)',
      backdropFilter: 'blur(20px) saturate(180%)',
      WebkitBackdropFilter: 'blur(20px) saturate(180%)',
      borderTop: `0.5px solid ${F.line}`,
      display: 'flex', justifyContent: 'space-around', alignItems: 'center',
      padding: '10px 8px 34px',
    }}>
      {items.map(it => {
        const isFab = it.id === 'plus';
        const active = tab === it.id;
        const Icon = it.icon;
        if (isFab) {
          return (
            <button key={it.id} onClick={() => setTab(it.id)} style={{
              width: 48, height: 48, borderRadius: 24,
              background: F.beam, border: 'none', cursor: 'pointer',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              boxShadow: '0 6px 16px rgba(245,166,35,0.4)',
              marginTop: -24,
            }}>
              <Icon size={22} color={F.navyDeep}/>
            </button>
          );
        }
        return (
          <button key={it.id} onClick={() => setTab(it.id)} style={{
            background: 'transparent', border: 'none', cursor: 'pointer',
            display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 3,
            padding: '4px 10px', minWidth: 54,
          }}>
            <Icon size={22} color={active ? F.beam : F.slate60}/>
            <span style={{
              fontSize: 10, fontWeight: 500, letterSpacing: 0.1,
              color: active ? F.navy : F.slate60,
            }}>{it.label}</span>
          </button>
        );
      })}
    </div>
  );
}

Object.assign(window, { F, BRL, Onboarding, HomeDashboard });
