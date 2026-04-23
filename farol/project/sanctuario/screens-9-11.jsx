// Screens 9-11: Swile detalle, Inversión alt, Onboarding

// ═════════════════════════════════════════════════════════════
// 09 · SWILE DETALLE — Beneficios
// ═════════════════════════════════════════════════════════════
function ScreenSwile() {
  return (
    <Screen tab="Tarjetas">
      <div style={{ overflowY: 'auto', height: '100%', paddingBottom: 16,
        background: S.surfaceLow }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          padding: '4px 24px 14px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <IcChevL size={18} color={S.onSurface}/>
            <div style={{ fontFamily: MANROPE, fontSize: 17, fontWeight: 800 }}>Farol</div>
          </div>
          <IcGear size={20} color={S.onSurface}/>
        </div>

        <div style={{ padding: '0 24px' }}>
          <div style={{ fontSize: 11, letterSpacing: 1.5, fontWeight: 700, color: S.onSurfaceSoft, textTransform: 'uppercase' }}>Beneficios Corporativos</div>
          <div style={{ fontFamily: MANROPE, fontSize: 32, fontWeight: 800, letterSpacing: -0.8, marginTop: 4 }}>Swile</div>
        </div>

        {/* Card hero */}
        <div style={{ margin: '18px 20px 14px', borderRadius: 22, padding: '24px 24px 22px',
          background: `linear-gradient(135deg, #F97366 0%, #E84840 100%)`, color: '#fff', position: 'relative', overflow: 'hidden' }}>
          <div style={{ position: 'absolute', top: -20, right: -20, width: 120, height: 120,
            borderRadius: '50%', background: 'rgba(255,255,255,0.1)' }}/>
          <div style={{ fontFamily: MANROPE, fontSize: 14, fontWeight: 800, letterSpacing: 1 }}>swile</div>
          <div style={{ marginTop: 36 }}>
            <div style={{ fontSize: 10, letterSpacing: 1.5, fontWeight: 700, opacity: 0.8, textTransform: 'uppercase' }}>Saldo Disponible</div>
            <div style={{ marginTop: 4 }}>
              <BRLBig value={1450.30} size={30} color="#fff" weight={800}/>
            </div>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 18, fontSize: 11, opacity: 0.9 }}>
            <span style={{ letterSpacing: 2, fontFamily: MANROPE }}>5320 ●●●● ●●●● 7891</span>
            <span>RICARDO A.</span>
          </div>
        </div>

        {/* Breakdown */}
        <div style={{ margin: '0 20px 12px', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
          <div style={{ background: S.surfaceLowest, borderRadius: 16, padding: 16 }}>
            <div style={{ fontSize: 10, letterSpacing: 1, fontWeight: 700, color: S.onSurfaceSoft, textTransform: 'uppercase' }}>Vale Alimentación</div>
            <div style={{ marginTop: 6 }}>
              <BRLSmall value={920.50} size={18} weight={800}/>
            </div>
            <div style={{ fontSize: 10, color: S.secondary, marginTop: 4, fontWeight: 600 }}>Renueva el 01/10</div>
          </div>
          <div style={{ background: S.surfaceLowest, borderRadius: 16, padding: 16 }}>
            <div style={{ fontSize: 10, letterSpacing: 1, fontWeight: 700, color: S.onSurfaceSoft, textTransform: 'uppercase' }}>Vale Refeição</div>
            <div style={{ marginTop: 6 }}>
              <BRLSmall value={529.80} size={18} weight={800}/>
            </div>
            <div style={{ fontSize: 10, color: S.secondary, marginTop: 4, fontWeight: 600 }}>Diario · R$ 33</div>
          </div>
        </div>

        {/* Gasto del mes chart */}
        <div style={{ margin: '0 20px 12px', background: S.surfaceLowest, borderRadius: 20, padding: 18 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div>
              <div style={{ fontFamily: MANROPE, fontSize: 15, fontWeight: 800 }}>Gasto del Mes</div>
              <div style={{ fontSize: 11, color: S.onSurfaceSoft, marginTop: 2 }}>Últimos 7 días</div>
            </div>
            <div style={{ textAlign: 'right' }}>
              <BRLSmall value={348.40} size={15} weight={800}/>
              <div style={{ fontSize: 10, color: S.secondary, fontWeight: 700 }}>+12% vs sem. anterior</div>
            </div>
          </div>
          <div style={{ marginTop: 14, display: 'flex', alignItems: 'flex-end', gap: 6, height: 80 }}>
            {[45, 68, 35, 82, 55, 28, 72].map((h, i) => (
              <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 6 }}>
                <div style={{ width: '100%', height: `${h}%`, borderRadius: '4px 4px 0 0',
                  background: i === 3 ? `linear-gradient(180deg, ${S.secondary}, ${S.tertiary})` : '#D4DBE3' }}/>
                <span style={{ fontSize: 9, color: S.onSurfaceFaint, fontWeight: 600 }}>{['L','M','X','J','V','S','D'][i]}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Últimas Transacciones */}
        <div style={{ padding: '4px 24px 0' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
            <div style={{ fontFamily: MANROPE, fontSize: 15, fontWeight: 800 }}>Últimas Transacciones</div>
            <div style={{ fontSize: 12, fontWeight: 600, color: S.secondary }}>Ver todas</div>
          </div>
          <TxSwile name="Restaurante Fasano" cat="REFEIÇÃO · HOJE, 13:45" value={89.90}/>
          <TxSwile name="Supermercado Pão de Açúcar" cat="ALIMENTAÇÃO · ONTEM" value={217.40}/>
          <TxSwile name="Cafeteria Santo Grão" cat="REFEIÇÃO · 12 SET" value={41.10}/>
        </div>
      </div>
    </Screen>
  );
}

function TxSwile({ name, cat, value }) {
  return (
    <div style={{ background: S.surfaceLowest, borderRadius: 16, padding: '14px 16px', marginBottom: 8,
      display: 'flex', alignItems: 'center', gap: 12 }}>
      <div style={{ width: 36, height: 36, borderRadius: 10, background: 'rgba(249,115,102,0.15)',
        display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <IcFork size={16} color="#E84840"/>
      </div>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 13, fontWeight: 600 }}>{name}</div>
        <div style={{ fontSize: 10, letterSpacing: 0.8, color: S.onSurfaceSoft, fontWeight: 700, marginTop: 2 }}>{cat}</div>
      </div>
      <BRLSmall value={-value} size={14} weight={700}/>
    </div>
  );
}

// ═════════════════════════════════════════════════════════════
// 10 · ALT: INVERSIÓN ACCIÓN — Itaú (variety)
// ═════════════════════════════════════════════════════════════
function ScreenAccion() {
  return (
    <Screen tab="Invertir">
      <div style={{ overflowY: 'auto', height: '100%', paddingBottom: 80, position: 'relative' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          padding: '4px 24px 12px' }}>
          <IcArrowBack size={20} color={S.onSurface}/>
          <div style={{ fontFamily: MANROPE, fontSize: 15, fontWeight: 700 }}>Activo</div>
          <IcDots size={20} color={S.onSurface}/>
        </div>

        <div style={{ padding: '0 24px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{ width: 48, height: 48, borderRadius: 12, background: '#EC7000',
              display: 'flex', alignItems: 'center', justifyContent: 'center',
              color: '#fff', fontFamily: MANROPE, fontWeight: 800, fontSize: 18 }}>I</div>
            <div>
              <div style={{ fontFamily: MANROPE, fontSize: 18, fontWeight: 800 }}>ITUB4</div>
              <div style={{ fontSize: 12, color: S.onSurfaceSoft }}>Itaú Unibanco PN</div>
            </div>
          </div>

          <div style={{ marginTop: 22 }}>
            <BRLBig value={31.84} size={40} weight={800}/>
            <div style={{ display: 'inline-flex', alignItems: 'center', gap: 4, marginTop: 6,
              padding: '4px 10px', borderRadius: 99, background: S.secondaryContainer,
              color: S.secondary, fontSize: 12, fontWeight: 700 }}>
              <IcTrendUp size={12} color={S.secondary}/> +R$ 0,48 · +1.54% hoy
            </div>
          </div>
        </div>

        {/* Candle-ish chart */}
        <div style={{ margin: '22px 20px 0', background: S.surfaceLowest, borderRadius: 20, padding: '20px 4px 12px' }}>
          <CandleChart/>
          <div style={{ display: 'flex', justifyContent: 'center', gap: 4, marginTop: 12 }}>
            {['1D','5D','1M','6M','1A','MAX'].map((t, i) => (
              <div key={t} style={{
                padding: '6px 12px', borderRadius: 99, fontSize: 11, fontWeight: 600,
                background: i === 2 ? S.primary : 'transparent',
                color: i === 2 ? '#fff' : S.onSurfaceSoft,
              }}>{t}</div>
            ))}
          </div>
        </div>

        {/* Estadísticas grid */}
        <div style={{ padding: '20px 24px 0' }}>
          <div style={{ fontFamily: MANROPE, fontSize: 15, fontWeight: 800, marginBottom: 12 }}>Estadísticas</div>
          <div style={{ background: S.surfaceLowest, borderRadius: 18, padding: '6px 18px' }}>
            <StatLine label="Apertura" value="R$ 31,36"/>
            <StatLine label="Máximo · Mínimo" value="R$ 32,10 · R$ 31,20"/>
            <StatLine label="Volumen" value="48.3M"/>
            <StatLine label="P/L" value="8,42"/>
            <StatLine label="Dividend Yield" value="5,20%" green/>
            <StatLine label="Valor de Mercado" value="R$ 311B" last/>
          </div>
        </div>

        {/* Tu posición */}
        <div style={{ margin: '20px 20px 0', borderRadius: 20, padding: 22,
          background: `linear-gradient(135deg, ${S.primaryContainer}, ${S.primary})`, color: '#fff' }}>
          <div style={{ fontSize: 10, letterSpacing: 1.5, fontWeight: 700, opacity: 0.7, textTransform: 'uppercase' }}>Tu posición</div>
          <div style={{ display: 'flex', justifyContent: 'space-between', marginTop: 14 }}>
            <div>
              <div style={{ fontSize: 10, opacity: 0.65, letterSpacing: 0.8, fontWeight: 600 }}>CANTIDAD</div>
              <div style={{ fontFamily: MANROPE, fontSize: 18, fontWeight: 800, marginTop: 2 }}>240</div>
            </div>
            <div>
              <div style={{ fontSize: 10, opacity: 0.65, letterSpacing: 0.8, fontWeight: 600 }}>PM</div>
              <div style={{ fontFamily: MANROPE, fontSize: 18, fontWeight: 800, marginTop: 2 }}>R$ 28,10</div>
            </div>
            <div>
              <div style={{ fontSize: 10, opacity: 0.65, letterSpacing: 0.8, fontWeight: 600 }}>GANANCIA</div>
              <div style={{ fontFamily: MANROPE, fontSize: 18, fontWeight: 800, marginTop: 2, color: S.secondaryFixed }}>+13.3%</div>
            </div>
          </div>
        </div>

        <div style={{ position: 'absolute', bottom: 16, left: 20, right: 20, display: 'flex', gap: 10 }}>
          <button style={{ flex: 1, height: 50, borderRadius: 16, border: 'none',
            background: S.secondary, color: '#fff',
            fontFamily: INTER, fontSize: 14, fontWeight: 700, cursor: 'pointer' }}>Comprar</button>
          <button style={{ flex: 1, height: 50, borderRadius: 16, border: `1.5px solid ${S.error}`,
            background: 'transparent', color: S.error,
            fontFamily: INTER, fontSize: 14, fontWeight: 700, cursor: 'pointer' }}>Vender</button>
        </div>
      </div>
    </Screen>
  );
}

function CandleChart() {
  const data = [
    { o: 30, c: 31, l: 29.5, h: 31.5 },
    { o: 31, c: 30.5, l: 30.2, h: 31.3 },
    { o: 30.5, c: 31.2, l: 30.3, h: 31.4 },
    { o: 31.2, c: 30.8, l: 30.5, h: 31.5 },
    { o: 30.8, c: 31.5, l: 30.7, h: 31.8 },
    { o: 31.5, c: 31, l: 30.8, h: 31.7 },
    { o: 31, c: 31.4, l: 30.9, h: 31.6 },
    { o: 31.4, c: 31.1, l: 30.9, h: 31.5 },
    { o: 31.1, c: 31.6, l: 31, h: 31.8 },
    { o: 31.6, c: 31.3, l: 31, h: 31.7 },
    { o: 31.3, c: 31.8, l: 31.1, h: 32 },
    { o: 31.8, c: 31.5, l: 31.3, h: 32.1 },
    { o: 31.5, c: 31.84, l: 31.2, h: 32.1 },
  ];
  const min = 29.3, max = 32.3, range = max - min;
  const w = 330, h = 140, cw = w / data.length;
  return (
    <svg viewBox={`0 0 ${w} ${h + 30}`} width="100%" height="170" style={{ display: 'block' }}>
      {[31, 30].map(v => {
        const y = h - ((v - min) / range) * h;
        return (
          <g key={v}>
            <line x1="0" x2={w} y1={y} y2={y} stroke={S.surfaceLow} strokeDasharray="3 4"/>
            <text x={w - 4} y={y - 3} textAnchor="end" style={{ fontFamily: INTER, fontSize: 9, fill: S.onSurfaceFaint }}>{v.toFixed(2)}</text>
          </g>
        );
      })}
      {data.map((d, i) => {
        const up = d.c >= d.o;
        const col = up ? S.secondary : S.error;
        const x = i * cw + cw / 2;
        const yH = h - ((d.h - min) / range) * h;
        const yL = h - ((d.l - min) / range) * h;
        const yO = h - ((d.o - min) / range) * h;
        const yC = h - ((d.c - min) / range) * h;
        return (
          <g key={i}>
            <line x1={x} x2={x} y1={yH} y2={yL} stroke={col} strokeWidth="1"/>
            <rect x={x - cw * 0.3} y={Math.min(yO, yC)} width={cw * 0.6}
              height={Math.max(2, Math.abs(yC - yO))} fill={col}/>
          </g>
        );
      })}
      {['28 AGO','4 SEP','11 SEP','18 SEP'].map((l, i) => (
        <text key={i} x={(i / 3) * w} y={h + 14} textAnchor={i === 0 ? 'start' : i === 3 ? 'end' : 'middle'}
          style={{ fontFamily: INTER, fontSize: 9, fill: S.onSurfaceFaint }}>{l}</text>
      ))}
    </svg>
  );
}

function StatLine({ label, value, green, last }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', padding: '11px 0',
      borderBottom: last ? 'none' : '1px solid rgba(195,198,207,0.25)' }}>
      <span style={{ fontSize: 12, color: S.onSurfaceSoft }}>{label}</span>
      <span style={{ fontSize: 13, fontWeight: 700, color: green ? S.secondary : S.onSurface,
        fontVariantNumeric: 'tabular-nums' }}>{value}</span>
    </div>
  );
}

// ═════════════════════════════════════════════════════════════
// 11 · ONBOARDING — Welcome
// ═════════════════════════════════════════════════════════════
function ScreenOnboarding() {
  return (
    <div style={{
      width: 390, height: 844, borderRadius: 38, overflow: 'hidden', position: 'relative',
      background: `linear-gradient(180deg, ${S.primaryDeep} 0%, ${S.primary} 60%, ${S.primaryContainer} 100%)`,
      fontFamily: INTER, color: '#fff',
      boxShadow: '0 24px 60px rgba(0,0,0,0.14), 0 0 0 1px rgba(0,0,0,0.05)',
      display: 'flex', flexDirection: 'column',
    }}>
      {/* aurora */}
      <div style={{ position: 'absolute', top: -80, left: -80, width: 320, height: 320, borderRadius: '50%',
        background: 'radial-gradient(circle, rgba(113,248,228,0.3), transparent 60%)' }}/>
      <div style={{ position: 'absolute', bottom: -100, right: -60, width: 300, height: 300, borderRadius: '50%',
        background: 'radial-gradient(circle, rgba(155,246,186,0.18), transparent 65%)' }}/>

      {/* status */}
      <div style={{ height: 44, paddingTop: 14, display: 'flex',
        justifyContent: 'space-between', alignItems: 'center', padding: '14px 26px 0',
        fontFamily: MANROPE, fontSize: 15, fontWeight: 700, color: '#fff', flexShrink: 0,
        position: 'relative', zIndex: 2 }}>
        <span>9:41</span>
        <div style={{ display: 'flex', gap: 5, alignItems: 'center' }}>
          <svg width="16" height="10" viewBox="0 0 16 10" fill="none">
            <rect x="0" y="6" width="3" height="4" rx="0.5" fill="#fff"/>
            <rect x="4.5" y="4" width="3" height="6" rx="0.5" fill="#fff"/>
            <rect x="9" y="2" width="3" height="8" rx="0.5" fill="#fff"/>
            <rect x="13.5" y="0" width="3" height="10" rx="0.5" fill="#fff"/>
          </svg>
          <svg width="14" height="10" viewBox="0 0 14 10" fill="none">
            <path d="M7 8.5a1 1 0 100-2 1 1 0 000 2zM1 3.5C2.7 2 4.8 1 7 1s4.3 1 6 2.5l-1.2 1.2c-1.3-1.2-3-1.9-4.8-1.9S3.5 3.5 2.2 4.7L1 3.5z" fill="#fff"/>
          </svg>
          <svg width="24" height="11" viewBox="0 0 24 11" fill="none">
            <rect x="0.5" y="0.5" width="21" height="10" rx="2.5" stroke="#fff" strokeOpacity="0.5"/>
            <rect x="2" y="2" width="18" height="7" rx="1.2" fill="#fff"/>
          </svg>
        </div>
      </div>

      <div style={{ flex: 1, position: 'relative', zIndex: 2, padding: '40px 32px 32px',
        display: 'flex', flexDirection: 'column' }}>

        {/* Logo mark — Farol lighthouse */}
        <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
          <div style={{ width: 44, height: 44, borderRadius: 12,
            background: '#F5A623',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            boxShadow: '0 8px 28px rgba(245,166,35,0.35)' }}>
            <svg width="26" height="26" viewBox="0 0 26 26" fill="none">
              {/* tower */}
              <path d="M10 22V10l3-4 3 4v12" stroke={S.primary} strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" fill="none"/>
              {/* beam */}
              <path d="M13 6L22 3" stroke={S.primary} strokeWidth="2" strokeLinecap="round"/>
              <path d="M10 22h6" stroke={S.primary} strokeWidth="2" strokeLinecap="round"/>
            </svg>
          </div>
          <div style={{ fontFamily: MANROPE, fontSize: 24, fontWeight: 800, letterSpacing: -0.5 }}>Farol</div>
        </div>

        <div style={{ flex: 1, display: 'flex', flexDirection: 'column', justifyContent: 'center', marginTop: -40 }}>
          <div style={{ fontSize: 11, letterSpacing: 2.5, fontWeight: 700, opacity: 0.7,
            textTransform: 'uppercase', color: S.secondaryFixed }}>Finanças com clareza</div>
          <div style={{ fontFamily: MANROPE, fontSize: 46, fontWeight: 800, letterSpacing: -1.6,
            lineHeight: 1.02, marginTop: 14 }}>
            Clareza para<br/>
            <span style={{ color: S.secondaryFixed }}>cada real.</span>
          </div>
          <div style={{ fontSize: 15, opacity: 0.75, marginTop: 20, lineHeight: 1.55, maxWidth: 300 }}>
            Seu dinheiro no rumo certo. Planejamento financeiro que guia cada decisão com clareza.
          </div>

          {/* feature chips */}
          <div style={{ marginTop: 34, display: 'flex', flexDirection: 'column', gap: 12 }}>
            <FeatureRow icon={<IcShield size={18} color={S.primary}/>} text="Segurança bancária e Pix integrado"/>
            <FeatureRow icon={<IcSparkle size={18} color={S.primary}/>} text="IA que entende seu salário CLT e FGTS"/>
            <FeatureRow icon={<IcHeadset size={18} color={S.primary}/>} text="Suporte em português, 24/7"/>
          </div>
        </div>

        {/* CTA */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          <button style={{
            width: '100%', height: 56, borderRadius: 18, border: 'none',
            background: 'linear-gradient(135deg, #9BF6BA 0%, #71F8E4 100%)',
            color: S.primary, fontFamily: INTER, fontWeight: 700, fontSize: 15,
            cursor: 'pointer', boxShadow: '0 12px 32px rgba(113,248,228,0.28)',
          }}>Criar minha conta Farol</button>
          <button style={{
            width: '100%', height: 52, borderRadius: 18, border: '1px solid rgba(255,255,255,0.18)',
            background: 'transparent', color: '#fff',
            fontFamily: INTER, fontWeight: 600, fontSize: 14, cursor: 'pointer',
          }}>Ya soy cliente · Iniciar sesión</button>

          <div style={{ display: 'flex', justifyContent: 'center', gap: 6, marginTop: 10 }}>
            <div style={{ width: 22, height: 4, borderRadius: 2, background: '#fff' }}/>
            <div style={{ width: 4, height: 4, borderRadius: 2, background: 'rgba(255,255,255,0.3)' }}/>
            <div style={{ width: 4, height: 4, borderRadius: 2, background: 'rgba(255,255,255,0.3)' }}/>
          </div>
        </div>
      </div>
    </div>
  );
}

function FeatureRow({ icon, text }) {
  return (
    <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
      <div style={{ width: 34, height: 34, borderRadius: 10,
        background: 'rgba(155,246,186,0.18)', border: '1px solid rgba(155,246,186,0.25)',
        display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
        <div style={{ width: 22, height: 22, borderRadius: 6, background: S.secondaryFixed,
          display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{icon}</div>
      </div>
      <span style={{ fontSize: 13, opacity: 0.9 }}>{text}</span>
    </div>
  );
}

Object.assign(window, { ScreenSwile, ScreenAccion, ScreenOnboarding });
