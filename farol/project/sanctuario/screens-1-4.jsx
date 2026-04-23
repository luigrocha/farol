// Screens 1-4: Ajustes, Análisis, Dashboard Home, Gastos

// ═════════════════════════════════════════════════════════════
// 01 · AJUSTES — "Ricardo Almeida" settings screen
// ═════════════════════════════════════════════════════════════
function ScreenAjustes() {
  return (
    <Screen tab="Ajustes" bg={S.surfaceLow}>
      <div style={{ overflowY: 'auto', height: '100%', paddingBottom: 20 }}>
        {/* header */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          padding: '4px 24px 20px' }}>
          <div style={{ fontFamily: MANROPE, fontSize: 22, fontWeight: 700, letterSpacing: -0.3 }}>Valora Pro</div>
          <IcGear size={22} color={S.onSurface}/>
        </div>

        {/* Profile card */}
        <div style={{ margin: '0 20px 16px', background: S.surfaceLowest, borderRadius: 24,
          padding: '22px 22px 24px' }}>
          <div style={{ fontFamily: INTER, fontSize: 11, fontWeight: 600, letterSpacing: 1.6,
            color: S.onSurfaceFaint, textTransform: 'uppercase' }}>Perfil Premium</div>
          <div style={{ fontFamily: MANROPE, fontSize: 28, fontWeight: 800, letterSpacing: -0.6,
            marginTop: 6, color: S.onSurface }}>Ricardo Almeida</div>
          <div style={{ display: 'flex', gap: 28, marginTop: 14, marginBottom: 18 }}>
            <div>
              <div style={{ fontSize: 11, color: S.onSurfaceSoft, marginBottom: 2 }}>Renta Mensual</div>
              <BRLSmall value={24500} size={15} weight={700}/>
            </div>
            <div>
              <div style={{ fontSize: 11, color: S.onSurfaceSoft, marginBottom: 2 }}>Plan Actual</div>
              <div style={{ display: 'inline-block', padding: '3px 10px', borderRadius: 99,
                background: S.secondaryContainer, color: S.secondary,
                fontSize: 10, fontWeight: 700, letterSpacing: 0.8 }}>ELITE PRO</div>
            </div>
          </div>
          <button style={{
            padding: '11px 20px', borderRadius: 14, border: 'none', cursor: 'pointer',
            background: `linear-gradient(135deg, ${S.primaryContainer}, ${S.primary})`,
            color: '#fff', fontFamily: INTER, fontSize: 14, fontWeight: 600,
          }}>Editar Perfil</button>
        </div>

        {/* Language */}
        <Section title="Language / Idioma" icon={<IcGlobe size={16} color={S.onSurfaceMuted}/>}>
          <LangRow flag="🇧🇷" name="Português" sub="Brasil" selected/>
          <LangRow flag="🇺🇸" name="English" sub="United States"/>
          <LangRow flag="🇪🇸" name="Español" sub="España"/>
        </Section>

        {/* Appearance — navy card */}
        <div style={{ margin: '24px 20px 0', borderRadius: 24, padding: 22,
          background: `linear-gradient(135deg, ${S.primaryContainer}, ${S.primary})`, color: '#fff' }}>
          <div style={{ fontFamily: MANROPE, fontSize: 18, fontWeight: 700 }}>Apariencia</div>
          <div style={{ fontSize: 12, opacity: 0.7, marginTop: 4, marginBottom: 16, lineHeight: 1.5 }}>
            Personalice su interfaz para el máximo confort visual.
          </div>
          <div style={{ display: 'flex', gap: 8, background: 'rgba(0,0,0,0.25)', padding: 4,
            borderRadius: 99 }}>
            <ThemeBtn label="Light" icon={<IcSun size={14} color={S.primary}/>} active/>
            <ThemeBtn label="Dark" icon={<IcMoon size={14} color="#fff"/>}/>
          </div>
        </div>

        {/* Data */}
        <Section title="Dados e Privacidade" icon={<IcShield size={16} color={S.onSurfaceMuted}/>}>
          <DataRow icon={<IcDoc size={18} color={S.secondary}/>} name="Exportar Transações" sub="Relatório mensal em PDF/CSV"/>
          <DataRow icon={<IcDoc size={18} color={S.primaryContainer}/>} name="Informe de Rendimentos" sub="Año base 2023"/>
        </Section>

        {/* Support */}
        <div style={{ padding: '24px 20px 0' }}>
          <div style={{ fontFamily: MANROPE, fontSize: 16, fontWeight: 700, marginBottom: 12 }}>Soporte Concierge</div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
            <SupportCard icon={<IcChatBubble size={22} color={S.secondary}/>} label="Chat 24/7"/>
            <SupportCard icon={<IcHeadset size={22} color={S.secondary}/>} label="Chamada VIP"/>
          </div>
        </div>

        <button style={{
          display: 'flex', gap: 8, alignItems: 'center', justifyContent: 'center',
          margin: '28px auto 0', background: 'none', border: 'none', cursor: 'pointer',
          color: S.error, fontFamily: INTER, fontSize: 15, fontWeight: 600,
        }}>
          <IcLogOut size={16} color={S.error}/>
          Sair da Conta
        </button>
      </div>
    </Screen>
  );
}

function Section({ title, icon, children }) {
  return (
    <div style={{ padding: '24px 20px 0' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 12 }}>
        {icon}
        <div style={{ fontFamily: MANROPE, fontSize: 15, fontWeight: 700, color: S.onSurface }}>{title}</div>
      </div>
      <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>{children}</div>
    </div>
  );
}

function LangRow({ flag, name, sub, selected }) {
  return (
    <div style={{
      background: S.surfaceLowest, borderRadius: 16, padding: '14px 16px',
      display: 'flex', alignItems: 'center', gap: 14, cursor: 'pointer',
      border: selected ? `2px solid ${S.secondary}` : '2px solid transparent',
    }}>
      <div style={{ width: 34, height: 34, borderRadius: 17, background: S.surfaceLow,
        display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 18 }}>{flag}</div>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 15, fontWeight: 600, color: S.onSurface }}>{name}</div>
        <div style={{ fontSize: 12, color: S.onSurfaceSoft, marginTop: 1 }}>{sub}</div>
      </div>
      {selected && <div style={{ width: 18, height: 18, borderRadius: 9,
        background: S.secondary, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <IcCheck size={12} color="#fff" strokeWidth={3}/>
      </div>}
    </div>
  );
}

function ThemeBtn({ label, icon, active }) {
  return (
    <button style={{
      flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center', gap: 6,
      padding: '10px 12px', borderRadius: 99, border: 'none', cursor: 'pointer',
      background: active ? '#fff' : 'transparent',
      color: active ? S.primary : '#fff',
      fontFamily: INTER, fontWeight: 600, fontSize: 13,
    }}>{icon}{label}</button>
  );
}

function DataRow({ icon, name, sub }) {
  return (
    <div style={{ background: S.surfaceLowest, borderRadius: 16, padding: '14px 16px',
      display: 'flex', alignItems: 'center', gap: 14 }}>
      <div style={{ width: 34, height: 34, borderRadius: 10, background: S.surfaceLow,
        display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{icon}</div>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 14, fontWeight: 600 }}>{name}</div>
        <div style={{ fontSize: 11, color: S.onSurfaceSoft, marginTop: 1 }}>{sub}</div>
      </div>
      <IcDownload size={18} color={S.onSurfaceSoft}/>
    </div>
  );
}

function SupportCard({ icon, label }) {
  return (
    <div style={{ background: S.surfaceLowest, borderRadius: 18, padding: 16,
      display: 'flex', flexDirection: 'column', gap: 10, alignItems: 'center' }}>
      <div style={{ width: 44, height: 44, borderRadius: 12,
        background: S.secondaryContainer,
        display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{icon}</div>
      <div style={{ fontSize: 13, fontWeight: 600, textAlign: 'center' }}>{label}</div>
    </div>
  );
}

// ═════════════════════════════════════════════════════════════
// 02 · ANÁLISIS DE GASTOS
// ═════════════════════════════════════════════════════════════
function ScreenAnalisis() {
  const cats = [
    { l: 'Vivienda',     pct: 40, c: S.primaryContainer },
    { l: 'Transporte',   pct: 25, c: S.tertiary },
    { l: 'Alimentación', pct: 20, c: S.secondary },
    { l: 'Ocio',         pct: 15, c: '#8FA3B8' },
  ];
  return (
    <Screen tab="Invertir">
      <div style={{ overflowY: 'auto', height: '100%', paddingBottom: 16 }}>
        {/* header */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          padding: '4px 24px 4px' }}>
          <div style={{ fontFamily: MANROPE, fontSize: 22, fontWeight: 800, letterSpacing: -0.3 }}>Sanctuario</div>
          <IcBell size={22} color={S.onSurface}/>
        </div>

        <div style={{ padding: '8px 24px 0' }}>
          <div style={{ fontFamily: MANROPE, fontSize: 32, fontWeight: 800, letterSpacing: -0.9,
            lineHeight: 1.1 }}>Análisis de Gastos</div>
          <div style={{ fontSize: 13, color: S.onSurfaceSoft, marginTop: 6 }}>
            Tu salud financiera proyectada en tiempo real.
          </div>
        </div>

        {/* Tabs */}
        <div style={{ display: 'flex', gap: 20, padding: '20px 24px 14px',
          borderBottom: `1px solid ${S.surfaceDim}` }}>
          {['Semana', 'Mes', 'Trimestre', 'Año'].map((t, i) => (
            <div key={t} style={{
              fontSize: 13, fontWeight: i === 1 ? 700 : 500,
              color: i === 1 ? S.secondary : S.onSurfaceSoft,
              paddingBottom: 8, position: 'relative',
            }}>
              {t}
              {i === 1 && <div style={{ position: 'absolute', bottom: -1, left: 0, right: 0,
                height: 2, background: S.secondary, borderRadius: 2 }}/>}
            </div>
          ))}
        </div>

        {/* Avg daily + bars */}
        <div style={{ margin: '16px 20px 0', background: S.surfaceLowest, borderRadius: 22, padding: 20 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div style={{ fontSize: 11, fontWeight: 700, letterSpacing: 1.2, color: S.onSurfaceSoft,
              textTransform: 'uppercase' }}>Gasto promedio diario</div>
            <div style={{ display: 'inline-flex', gap: 3, alignItems: 'center',
              padding: '3px 8px', borderRadius: 99, background: S.secondaryContainer,
              color: S.secondary, fontSize: 11, fontWeight: 700 }}>
              <IcTrendDown size={11} color={S.secondary}/>12.6%
            </div>
          </div>
          <div style={{ marginTop: 10 }}>
            <BRLBig value={142.80} size={44}/>
          </div>
          <div style={{ marginTop: 16, display: 'flex', gap: 6, alignItems: 'flex-end', height: 80 }}>
            {[40, 55, 48, 70, 60, 82, 95, 50].map((h, i) => (
              <div key={i} style={{
                flex: 1, height: `${h}%`, borderRadius: 5,
                background: i === 6 ? S.primaryContainer : '#D4DBE3',
              }}/>
            ))}
          </div>
        </div>

        {/* Proyección Pro card */}
        <div style={{ margin: '16px 20px 0', borderRadius: 22, padding: 22,
          background: `linear-gradient(135deg, ${S.primaryContainer}, ${S.primary})`, color: '#fff', position: 'relative', overflow: 'hidden' }}>
          <div style={{ position: 'absolute', top: -30, right: -30, width: 160, height: 160,
            borderRadius: '50%', background: 'radial-gradient(circle, rgba(113,248,228,0.18), transparent 65%)' }}/>
          <IcSparkle size={18} color={S.tertiaryFixed}/>
          <div style={{ fontFamily: MANROPE, fontSize: 18, fontWeight: 700, marginTop: 10 }}>Proyección Pro</div>
          <div style={{ fontSize: 13, opacity: 0.8, marginTop: 6, marginBottom: 16, lineHeight: 1.5 }}>
            Según tus hábitos, podrías ahorrar un <span style={{ color: S.secondaryFixed, fontWeight: 600 }}>15% adicional</span> este trimestre reduciendo gastos en ocio nocturno.
          </div>
          <button style={{ padding: '12px 18px', borderRadius: 99,
            background: S.secondaryFixed, color: S.primary, border: 'none',
            fontFamily: INTER, fontWeight: 700, fontSize: 13, cursor: 'pointer' }}>
            Ver sugerencias
          </button>
        </div>

        {/* Distribución donut */}
        <div style={{ padding: '24px 24px 0' }}>
          <div style={{ fontFamily: MANROPE, fontSize: 17, fontWeight: 700 }}>Distribución por Categoría</div>
          <div style={{ display: 'flex', justifyContent: 'center', marginTop: 16 }}>
            <DonutChart cats={cats} total={4290}/>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10, marginTop: 16 }}>
            {cats.map(c => (
              <div key={c.l} style={{ background: S.surfaceLowest, borderRadius: 14, padding: '10px 12px' }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
                  <div style={{ width: 8, height: 8, borderRadius: 4, background: c.c }}/>
                  <div style={{ fontSize: 10, letterSpacing: 0.8, color: S.onSurfaceSoft,
                    textTransform: 'uppercase', fontWeight: 600 }}>{c.l}</div>
                </div>
                <div style={{ fontFamily: MANROPE, fontSize: 17, fontWeight: 700, marginTop: 4 }}>{c.pct}%</div>
              </div>
            ))}
          </div>
        </div>

        {/* Trend */}
        <div style={{ padding: '24px 24px 0' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div style={{ fontFamily: MANROPE, fontSize: 17, fontWeight: 700 }}>Tendencia de Gasto</div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 11,
              color: S.onSurfaceSoft }}>
              <div style={{ width: 10, height: 2, background: S.secondary, borderRadius: 1 }}/>
              Gasto Real
            </div>
          </div>
          <div style={{ marginTop: 12, background: S.surfaceLowest, borderRadius: 18, padding: 18 }}>
            <TrendChart/>
          </div>
        </div>

        {/* cat list */}
        <div style={{ padding: '18px 20px 0' }}>
          <CatRow icon={<IcFork size={18} color={S.secondary}/>} label="Alimentación" sub="42 transacciones" value={858} pct="+2.4%" up/>
          <CatRow icon={<IcCar size={18} color={S.tertiary}/>} label="Transporte" sub="19 transacciones" value={1072.50} pct="−5.1%"/>
        </div>
      </div>
    </Screen>
  );
}

function DonutChart({ cats, total }) {
  const r = 72, stroke = 20, C = 2 * Math.PI * r;
  let acc = 0;
  return (
    <svg width="180" height="180" viewBox="0 0 180 180">
      <circle cx="90" cy="90" r={r} fill="none" stroke={S.surfaceLow} strokeWidth={stroke}/>
      {cats.map((c, i) => {
        const len = (c.pct / 100) * C;
        const off = -acc;
        acc += len;
        return (
          <circle key={i} cx="90" cy="90" r={r} fill="none"
            stroke={c.c} strokeWidth={stroke}
            strokeDasharray={`${len} ${C}`}
            strokeDashoffset={off}
            transform="rotate(-90 90 90)"
            strokeLinecap="butt"/>
        );
      })}
      <text x="90" y="83" textAnchor="middle" style={{ fontFamily: INTER, fontSize: 10, fill: S.onSurfaceSoft, fontWeight: 600, letterSpacing: 1 }}>TOTAL</text>
      <text x="90" y="104" textAnchor="middle" style={{ fontFamily: MANROPE, fontSize: 20, fill: S.onSurface, fontWeight: 800 }}>R$ 4.290</text>
    </svg>
  );
}

function TrendChart() {
  const pts = [30, 45, 40, 55, 48, 62, 58];
  const w = 300, h = 80;
  const xs = pts.map((_, i) => (i / (pts.length - 1)) * w);
  const ys = pts.map(p => h - (p / 70) * h);
  const d = xs.map((x, i) => `${i === 0 ? 'M' : 'L'}${x},${ys[i]}`).join(' ');
  const area = `${d} L${w},${h} L0,${h} Z`;
  return (
    <svg viewBox={`0 0 ${w} ${h + 20}`} width="100%" height="100" style={{ display: 'block' }}>
      <defs>
        <linearGradient id="trendGrad" x1="0" x2="0" y1="0" y2="1">
          <stop offset="0" stopColor={S.secondary} stopOpacity="0.18"/>
          <stop offset="1" stopColor={S.secondary} stopOpacity="0"/>
        </linearGradient>
      </defs>
      <path d={area} fill="url(#trendGrad)"/>
      <path d={d} fill="none" stroke={S.secondary} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"/>
      {xs.map((x, i) => (
        <text key={i} x={x} y={h + 14} textAnchor="middle"
          style={{ fontFamily: INTER, fontSize: 9, fill: S.onSurfaceFaint }}>
          {['ENE','FEB','MAR','ABR','MAY','JUN','JUL'][i]}
        </text>
      ))}
    </svg>
  );
}

function CatRow({ icon, label, sub, value, pct, up }) {
  return (
    <div style={{ background: S.surfaceLowest, borderRadius: 16, padding: '14px 16px',
      display: 'flex', alignItems: 'center', gap: 12, marginBottom: 8 }}>
      <div style={{ width: 36, height: 36, borderRadius: 18, background: S.secondaryContainer,
        display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{icon}</div>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 14, fontWeight: 600 }}>{label}</div>
        <div style={{ fontSize: 11, color: S.onSurfaceSoft, marginTop: 1 }}>{sub}</div>
      </div>
      <div style={{ textAlign: 'right' }}>
        <BRLSmall value={value} size={14} weight={700}/>
        <div style={{ fontSize: 11, fontWeight: 600, color: up ? S.secondary : S.error, marginTop: 2 }}>{pct}</div>
      </div>
    </div>
  );
}

// ═════════════════════════════════════════════════════════════
// 03 · DASHBOARD HOME ("Patrimônio Neto Estimado")
// ═════════════════════════════════════════════════════════════
function ScreenHome() {
  return (
    <Screen tab="Inicio">
      <div style={{ overflowY: 'auto', height: '100%', paddingBottom: 16 }}>
        {/* header */}
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          padding: '4px 20px 10px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <IcChevL size={18} color={S.onSurface}/>
            <div style={{ fontFamily: MANROPE, fontSize: 16, fontWeight: 700 }}>Septiembre 2023</div>
          </div>
          <IcCal size={20} color={S.onSurface}/>
        </div>

        {/* Hero card */}
        <div style={{ margin: '8px 16px 14px', borderRadius: 24, padding: '22px 22px 20px',
          background: `linear-gradient(135deg, ${S.primaryContainer}, ${S.primary})`, color: '#fff' }}>
          <div style={{ fontSize: 10, letterSpacing: 1.5, fontWeight: 700, opacity: 0.65,
            textTransform: 'uppercase' }}>Patrimonio Neto Estimado</div>
          <div style={{ marginTop: 6 }}>
            <BRLBig value={142850} size={36} color="#fff" weight={800}/>
          </div>
          <div style={{ display: 'flex', gap: 10, marginTop: 16 }}>
            <MiniStat label="Invertido" value={98400} color="#fff"/>
            <MiniStat label="Líquido FGTS + R" value={44450} color={S.tertiaryFixed}/>
          </div>
        </div>

        {/* Salud Financiera */}
        <div style={{ margin: '0 16px 12px', background: S.surfaceLowest, borderRadius: 20, padding: 18,
          display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
          <div style={{ fontFamily: MANROPE, fontSize: 15, fontWeight: 700, alignSelf: 'flex-start' }}>Salud Financiera</div>
          <GaugeRing score={85}/>
          <div style={{ fontSize: 11, fontStyle: 'italic', color: S.onSurfaceSoft, textAlign: 'center', marginTop: 8 }}>
            "Su tasa de interés es un 12% superior a la media de su perfil."
          </div>
        </div>

        {/* Grid of KPIs */}
        <div style={{ margin: '0 16px', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 8 }}>
          <KpiCard icon={<IcWallet size={16} color={S.primaryContainer}/>} bg="#E3ECFA" label="Salario Neto" value={9651.91}/>
          <KpiCard icon={<IcCup size={16} color={S.secondary}/>} bg={S.secondaryContainer} label="Beneficio in Swile" value={2431.00}/>
          <KpiCard icon={<IcTrendUp size={16} color={S.secondary}/>} bg={S.secondaryContainer} label="Total Disponible" value={12082.91}/>
          <KpiCard icon={<IcTrendDown size={16} color={S.error}/>} bg="#FDE7E5" label="Gastos Totales" value={6120.40}/>
          <KpiCard icon={<IcTrendUp size={16} color={S.secondary}/>} bg={S.secondaryContainer} label="Balance Mensual" value={5962.51} positive/>
          <KpiCard icon={<IcTrendUp size={16} color={S.primaryContainer}/>} bg="#E3ECFA" label="Tasa de Ahorro" raw="49.3%"/>
        </div>

        {/* Gastos por Categoría */}
        <div style={{ margin: '14px 16px 0', background: S.surfaceLowest, borderRadius: 20, padding: 18 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div style={{ fontFamily: MANROPE, fontSize: 15, fontWeight: 700 }}>Gastos por Categoría</div>
            <div style={{ fontSize: 10, letterSpacing: 1, color: S.onSurfaceSoft, textTransform: 'uppercase' }}>Actual vs Presupuesto</div>
          </div>
          <div style={{ marginTop: 14, display: 'flex', flexDirection: 'column', gap: 14 }}>
            <CatBudget label="Vivienda"    spent={2450} cap={2500}/>
            <CatBudget label="Transporte"  spent={1160} cap={1500}/>
            <CatBudget label="Alimentación" spent={1200} cap={1100}/>
            <CatBudget label="Ocio"        spent={840}  cap={1000}/>
          </div>
        </div>

        {/* Meta mensual */}
        <div style={{ margin: '12px 16px 0', background: S.surfaceLowest, borderRadius: 20, padding: 18 }}>
          <div style={{ fontFamily: MANROPE, fontSize: 14, fontWeight: 700 }}>Meta Mensual</div>
          <div style={{ fontSize: 12, color: S.onSurfaceSoft, marginTop: 4 }}>
            Faltan <b style={{ color: S.onSurface }}>R$ 572,00</b> para alcanzar tu meta de ahorro este mes.
          </div>
          <div style={{ marginTop: 12, display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{ flex: 1, height: 8, background: S.secondaryContainer, borderRadius: 4, overflow: 'hidden' }}>
              <div style={{ width: '82%', height: '100%', background: S.secondary, borderRadius: 4 }}/>
            </div>
            <span style={{ fontSize: 12, fontWeight: 700, color: S.secondary, fontVariantNumeric: 'tabular-nums' }}>82%</span>
          </div>
        </div>

        {/* Alfa */}
        <div style={{ margin: '12px 16px 0', background: S.surfaceLowest, borderRadius: 20, padding: 18,
          display: 'flex', alignItems: 'center', gap: 14 }}>
          <div style={{ width: 44, height: 44, borderRadius: 12, background: S.secondaryContainer,
            display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <IcTrendUp size={22} color={S.secondary}/>
          </div>
          <div style={{ flex: 1 }}>
            <div style={{ fontSize: 11, letterSpacing: 1, fontWeight: 600, color: S.secondary,
              textTransform: 'uppercase' }}>+2.4% este mes</div>
            <div style={{ fontSize: 11, color: S.onSurfaceSoft, marginTop: 2 }}>RENDIMIENTO DEL PORTAFOLIO</div>
            <div style={{ fontFamily: MANROPE, fontSize: 22, fontWeight: 800, marginTop: 2, color: S.secondary }}>Alfa +12.4%</div>
          </div>
        </div>
      </div>
    </Screen>
  );
}

function MiniStat({ label, value, color = '#fff' }) {
  return (
    <div style={{ flex: 1, background: 'rgba(255,255,255,0.08)', borderRadius: 14,
      padding: '10px 12px', border: '1px solid rgba(255,255,255,0.08)' }}>
      <div style={{ fontSize: 9, letterSpacing: 1, fontWeight: 600, opacity: 0.65, textTransform: 'uppercase' }}>{label}</div>
      <div style={{ marginTop: 4 }}>
        <BRLBig value={value} size={16} color={color} weight={700}/>
      </div>
    </div>
  );
}

function GaugeRing({ score }) {
  const r = 40, stroke = 8, C = 2 * Math.PI * r;
  const arc = (score / 100) * C;
  return (
    <div style={{ position: 'relative', width: 120, height: 120, margin: '10px 0' }}>
      <svg width="120" height="120" viewBox="0 0 120 120">
        <circle cx="60" cy="60" r={r} fill="none" stroke={S.surfaceLow} strokeWidth={stroke}/>
        <circle cx="60" cy="60" r={r} fill="none" stroke={S.secondary} strokeWidth={stroke}
          strokeDasharray={`${arc} ${C}`} strokeLinecap="round"
          transform="rotate(-90 60 60)"/>
      </svg>
      <div style={{ position: 'absolute', inset: 0, display: 'flex', flexDirection: 'column',
        alignItems: 'center', justifyContent: 'center' }}>
        <div style={{ fontFamily: MANROPE, fontSize: 30, fontWeight: 800, letterSpacing: -0.5 }}>{score}</div>
        <div style={{ fontSize: 10, color: S.secondary, fontWeight: 700, letterSpacing: 1, textTransform: 'uppercase' }}>Óptima</div>
      </div>
    </div>
  );
}

function KpiCard({ icon, bg, label, value, raw, positive }) {
  return (
    <div style={{ background: S.surfaceLowest, borderRadius: 16, padding: 14 }}>
      <div style={{ width: 28, height: 28, borderRadius: 8, background: bg,
        display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{icon}</div>
      <div style={{ fontSize: 11, color: S.onSurfaceSoft, marginTop: 10, fontWeight: 500 }}>{label}</div>
      {raw ? (
        <div style={{ fontFamily: MANROPE, fontSize: 18, fontWeight: 800, marginTop: 2, color: positive ? S.secondary : S.onSurface }}>{raw}</div>
      ) : (
        <div style={{ marginTop: 2 }}>
          <BRLSmall value={positive ? value : value} size={15} weight={700}
            color={positive ? S.secondary : S.onSurface}/>
        </div>
      )}
    </div>
  );
}

function CatBudget({ label, spent, cap }) {
  const pct = Math.min(spent / cap, 1);
  const over = spent > cap;
  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 6 }}>
        <span style={{ fontSize: 13, fontWeight: 500 }}>{label}</span>
        <span style={{ fontSize: 11, color: over ? S.error : S.onSurfaceSoft, fontVariantNumeric: 'tabular-nums' }}>
          R$ {spent.toLocaleString('pt-BR')} / R$ {cap.toLocaleString('pt-BR')}
        </span>
      </div>
      <div style={{ height: 6, background: S.surfaceLow, borderRadius: 3, overflow: 'hidden' }}>
        <div style={{ width: `${pct * 100}%`, height: '100%',
          background: over ? S.error : S.secondary, borderRadius: 3 }}/>
      </div>
    </div>
  );
}

// ═════════════════════════════════════════════════════════════
// 04 · GASTOS list
// ═════════════════════════════════════════════════════════════
function ScreenGastos() {
  return (
    <Screen tab="Inicio">
      <div style={{ overflowY: 'auto', height: '100%', paddingBottom: 16, position: 'relative' }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          padding: '4px 20px 16px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <Avatar/>
            <div style={{ fontFamily: MANROPE, fontSize: 17, fontWeight: 700 }}>Septiembre 2023</div>
          </div>
          <IcCal size={22} color={S.onSurface}/>
        </div>

        {/* search */}
        <div style={{ margin: '0 20px', background: S.surfaceLowest, borderRadius: 99, padding: '12px 16px',
          display: 'flex', alignItems: 'center', gap: 10 }}>
          <IcSearch size={18} color={S.onSurfaceFaint}/>
          <span style={{ fontSize: 14, color: S.onSurfaceFaint }}>Buscar gasto...</span>
        </div>

        {/* chips */}
        <div style={{ display: 'flex', gap: 8, padding: '14px 20px', overflowX: 'auto' }}>
          {['Todas','Categoría','Mes','Swile'].map((c, i) => (
            <div key={c} style={{
              padding: '10px 18px', borderRadius: 99, flexShrink: 0,
              background: i === 0 ? S.primary : S.surfaceLowest,
              color: i === 0 ? '#fff' : S.onSurface,
              fontSize: 13, fontWeight: 600,
            }}>{c}</div>
          ))}
        </div>

        {/* Total card */}
        <div style={{ margin: '6px 20px 0', borderRadius: 22, padding: '22px 22px',
          background: `linear-gradient(135deg, ${S.primaryContainer}, ${S.primary})`, color: '#fff' }}>
          <div style={{ fontSize: 10, letterSpacing: 1.8, fontWeight: 700, opacity: 0.65, textTransform: 'uppercase' }}>Total Mensual</div>
          <div style={{ marginTop: 6 }}>
            <BRLBig value={4285.50} size={32} color="#fff" weight={800}/>
          </div>
          <div style={{ marginTop: 18, display: 'flex', flexDirection: 'column', gap: 12 }}>
            <HeroBar label="Alimentación" value={1840} pct={70} color={S.secondaryFixed}/>
            <HeroBar label="Movilidad"    value={620}  pct={35} color={S.tertiaryFixed}/>
            <HeroBar label="Ocio"         value={1200} pct={22} color="rgba(255,255,255,0.5)"/>
          </div>
        </div>

        {/* Day section */}
        <DaySeparator date="HOY, 14 DE SEPTIEMBRE" total={254}/>
        <TxRow icon={<IcFork size={18} color={S.onSurfaceMuted}/>} name="Restaurante Sabor Real" cat="Alimentación" tag="SWILE" value={158.50} time="12:30"/>
        <TxRow icon={<IcCar size={18} color={S.onSurfaceMuted}/>} name="Uber Viaje" cat="Movilidad" pay="EFECTIVO" value={95.50} time="08:15"/>

        <DaySeparator date="AYER, 13 DE SEPTIEMBRE" total={1120}/>
        <TxRow icon={<IcBag size={18} color={S.onSurfaceMuted}/>} name="Zara Shopping Iguatemi" cat="Vestuario" pay="TARJETA" value={840} time="19:45"/>
        <TxRow icon={<IcFork size={18} color={S.onSurfaceMuted}/>} name="Pão de Açúcar" cat="Alimentación" tag="SWILE" value={280} time="17:20"/>

        <div style={{ height: 80 }}/>

        {/* FAB */}
        <button style={{
          position: 'absolute', right: 20, bottom: 20,
          width: 52, height: 52, borderRadius: 26,
          background: S.secondaryFixed, border: 'none', cursor: 'pointer',
          display: 'flex', alignItems: 'center', justifyContent: 'center',
          boxShadow: '0 8px 20px rgba(155,246,186,0.5)',
        }}>
          <IcPlus size={22} color={S.primary}/>
        </button>
      </div>
    </Screen>
  );
}

function Avatar() {
  return (
    <div style={{
      width: 36, height: 36, borderRadius: 18,
      background: `linear-gradient(135deg, ${S.tertiary}, ${S.secondary})`,
      display: 'flex', alignItems: 'center', justifyContent: 'center',
      color: '#fff', fontFamily: MANROPE, fontWeight: 800, fontSize: 14,
    }}>RA</div>
  );
}

function HeroBar({ label, value, pct, color }) {
  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginBottom: 6 }}>
        <span style={{ fontSize: 13, opacity: 0.9 }}>{label}</span>
        <BRLSmall value={value} size={13} weight={600} color="#fff"/>
      </div>
      <div style={{ height: 4, background: 'rgba(255,255,255,0.12)', borderRadius: 2, overflow: 'hidden' }}>
        <div style={{ width: `${pct}%`, height: '100%', background: color, borderRadius: 2 }}/>
      </div>
    </div>
  );
}

function DaySeparator({ date, total }) {
  return (
    <div style={{ padding: '22px 24px 10px', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
      <div style={{ fontSize: 10, letterSpacing: 1.2, color: S.onSurfaceSoft, fontWeight: 700, textTransform: 'uppercase' }}>{date}</div>
      <BRLSmall value={total} size={12} color={S.onSurfaceSoft} weight={600}/>
    </div>
  );
}

function TxRow({ icon, name, cat, tag, pay, value, time }) {
  return (
    <div style={{ margin: '0 20px 8px', background: S.surfaceLowest, borderRadius: 16,
      padding: '14px 16px', display: 'flex', alignItems: 'center', gap: 14 }}>
      <div style={{ width: 38, height: 38, borderRadius: 19, background: S.surfaceLow,
        display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{icon}</div>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 14, fontWeight: 600, color: S.onSurface, lineHeight: 1.3 }}>{name}</div>
        <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 4 }}>
          <span style={{ fontSize: 11, color: S.onSurfaceSoft }}>{cat}</span>
          <span style={{ width: 3, height: 3, borderRadius: 2, background: S.onSurfaceFaint }}/>
          {tag ? (
            <span style={{ fontSize: 9, fontWeight: 700, padding: '2px 8px', borderRadius: 6,
              background: 'rgba(113,248,228,0.3)', color: S.tertiary, letterSpacing: 0.5 }}>{tag}</span>
          ) : <span style={{ fontSize: 10, color: S.onSurfaceSoft, letterSpacing: 0.5, fontWeight: 600 }}>{pay}</span>}
        </div>
      </div>
      <div style={{ textAlign: 'right' }}>
        <BRLSmall value={value} size={15} weight={700}/>
        <div style={{ fontSize: 11, color: S.onSurfaceFaint, marginTop: 2 }}>{time}</div>
      </div>
    </div>
  );
}

Object.assign(window, { ScreenAjustes, ScreenAnalisis, ScreenHome, ScreenGastos, Avatar });
