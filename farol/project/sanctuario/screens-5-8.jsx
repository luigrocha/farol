// Screens 5-8: Inversión detalle, Portafolio, Metas, Notificaciones

// ═════════════════════════════════════════════════════════════
// 05 · INVERSIÓN DETALLE — Tesouro Selic 2029
// ═════════════════════════════════════════════════════════════
function ScreenInversion() {
  return (
    <Screen tab="Invertir">
      <div style={{ overflowY: 'auto', height: '100%', paddingBottom: 80, position: 'relative' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          padding: '4px 24px 12px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <div style={{ width: 28, height: 28, borderRadius: 14, background: S.primary,
              display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <div style={{ width: 10, height: 10, borderRadius: 5, background: S.tertiaryFixed }}/>
            </div>
            <div style={{ fontFamily: MANROPE, fontSize: 18, fontWeight: 800 }}>Sanctuario</div>
          </div>
          <IcBell size={22} color={S.onSurface}/>
        </div>

        <div style={{ padding: '0 24px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, fontSize: 13,
            color: S.onSurfaceSoft, marginBottom: 10 }}>
            <IcArrowBack size={14} color={S.onSurfaceSoft}/> Volver a Cartera
          </div>
          <div style={{ fontFamily: MANROPE, fontSize: 30, fontWeight: 800, letterSpacing: -0.6, lineHeight: 1.1 }}>
            Tesouro Selic 2029
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginTop: 10 }}>
            <span style={{ padding: '4px 10px', borderRadius: 99, background: S.secondaryContainer,
              color: S.secondary, fontSize: 10, fontWeight: 700, letterSpacing: 1 }}>RENTA FIJA</span>
            <span style={{ display: 'inline-flex', alignItems: 'center', gap: 3, color: S.secondary,
              fontSize: 12, fontWeight: 700 }}>
              <IcTrendUp size={12} color={S.secondary}/> +12.4% este año
            </span>
          </div>
          <div style={{ fontSize: 10, letterSpacing: 1.5, color: S.onSurfaceSoft, fontWeight: 700,
            textTransform: 'uppercase', marginTop: 22 }}>Valor Actual</div>
          <div style={{ marginTop: 6 }}>
            <BRLBig value={14250.80} size={36} weight={800}/>
          </div>
        </div>

        {/* Chart */}
        <div style={{ margin: '20px 20px 0', background: S.surfaceLowest, borderRadius: 20, padding: '18px 18px 14px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div style={{ fontFamily: MANROPE, fontSize: 14, fontWeight: 700 }}>Rendimiento Histórico</div>
            <div style={{ display: 'flex', gap: 4 }}>
              {['1M','6M','1A','MAX'].map((t, i) => (
                <div key={t} style={{
                  padding: '4px 10px', borderRadius: 8, fontSize: 11, fontWeight: 600,
                  background: i === 2 ? S.primary : 'transparent',
                  color: i === 2 ? '#fff' : S.onSurfaceSoft,
                }}>{t}</div>
              ))}
            </div>
          </div>
          <InvestmentChart/>
        </div>

        {/* 4 metrics */}
        <div style={{ margin: '14px 20px 0', display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
          <MetricCard label="Precio de Compra"><BRLSmall value={12140} size={16} weight={700}/></MetricCard>
          <MetricCard label="Cantidad"><span style={{ fontFamily: MANROPE, fontSize: 16, fontWeight: 800 }}>1.24 Títulos</span></MetricCard>
          <MetricCard label="Retorno Total" green>
            <BRLSmall value={2110.80} size={16} weight={700} color={S.secondary}/>
            <div style={{ fontSize: 11, fontWeight: 600, color: S.secondary, marginTop: 2 }}>+17.38%</div>
          </MetricCard>
          <MetricCard label="Yield Actual">
            <span style={{ fontFamily: MANROPE, fontSize: 20, fontWeight: 800 }}>11.75%</span>
            <div style={{ fontSize: 11, color: S.onSurfaceSoft, marginTop: 2 }}>a.a.</div>
          </MetricCard>
        </div>

        {/* Liquidez card */}
        <div style={{ margin: '14px 20px 0', borderRadius: 20, padding: 20,
          background: `linear-gradient(135deg, ${S.primaryContainer}, ${S.primary})`, color: '#fff', position: 'relative', overflow: 'hidden' }}>
          <svg style={{ position: 'absolute', top: 12, right: 16 }} width="40" height="20" viewBox="0 0 40 20" fill="none">
            <path d="M0 8c5-6 10-6 15 0s10 6 15 0 10-6 10 0" stroke={S.tertiaryFixed} strokeWidth="1.5" opacity="0.5"/>
            <path d="M0 14c5-6 10-6 15 0s10 6 15 0 10-6 10 0" stroke={S.tertiaryFixed} strokeWidth="1.5" opacity="0.7"/>
          </svg>
          <div style={{ fontFamily: MANROPE, fontSize: 16, fontWeight: 700, marginTop: 24 }}>Liquidez Diaria</div>
          <div style={{ fontSize: 12, opacity: 0.8, marginTop: 6, lineHeight: 1.5 }}>
            Disponible en D+0. Los fondos se acreditan inmediatamente en su cuenta Sanctuario.
          </div>
          <div style={{ marginTop: 18, paddingTop: 12, borderTop: '1px solid rgba(255,255,255,0.1)',
            display: 'flex', justifyContent: 'space-between', fontSize: 10, letterSpacing: 1, fontWeight: 700, opacity: 0.75, textTransform: 'uppercase' }}>
            <span>Nivel de Riesgo</span>
            <span style={{ color: S.tertiaryFixed }}>BAJO</span>
          </div>
        </div>

        {/* Actividad */}
        <div style={{ margin: '18px 24px 0' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
            <div style={{ fontFamily: MANROPE, fontSize: 16, fontWeight: 700 }}>Historial de Actividad</div>
            <div style={{ fontSize: 12, color: S.secondary, fontWeight: 600 }}>Ver Todo</div>
          </div>
          <ActRow icon={<IcTrendUp size={16} color={S.secondary}/>} name="Aporte Mensual" date="12 DE OCTUBRE, 2023" value={500} tag="COMPLETADO"/>
          <ActRow icon={<IcDoc size={16} color={S.secondary}/>} name="Pago de Cupones" date="01 DE SEPTIEMBRE, 2023" value={142.50} tag="REINVERTIDO" positive/>
          <ActRow icon={<IcWallet size={16} color={S.secondary}/>} name="Compra Inicial" date="15 DE ENERO, 2023" value={11497.50}/>
        </div>

        {/* Bottom actions */}
        <div style={{ position: 'absolute', bottom: 16, left: 20, right: 20, display: 'flex', gap: 10 }}>
          <button style={{ flex: 1, height: 48, borderRadius: 16, border: 'none',
            background: `linear-gradient(135deg, ${S.primaryContainer}, ${S.primary})`, color: '#fff',
            fontFamily: INTER, fontSize: 14, fontWeight: 700, cursor: 'pointer' }}>Invertir más</button>
          <button style={{ flex: 1, height: 48, borderRadius: 16,
            background: S.surfaceLowest, color: S.onSurface, border: 'none',
            fontFamily: INTER, fontSize: 14, fontWeight: 700, cursor: 'pointer' }}>Retirar</button>
        </div>
      </div>
    </Screen>
  );
}

function InvestmentChart() {
  const pts = [30, 35, 50, 45, 60, 52, 78, 72, 65, 80, 72, 84];
  const w = 300, h = 100;
  const xs = pts.map((_, i) => (i / (pts.length - 1)) * w);
  const ys = pts.map(p => h - (p / 90) * h);
  const d = xs.map((x, i) => `${i === 0 ? 'M' : 'L'}${x},${ys[i]}`).join(' ');
  const area = `${d} L${w},${h} L0,${h} Z`;
  const hi = 6;
  return (
    <svg viewBox={`0 0 ${w} ${h + 26}`} width="100%" height="140" style={{ display: 'block', marginTop: 14 }}>
      <defs>
        <linearGradient id="invGrad" x1="0" x2="0" y1="0" y2="1">
          <stop offset="0" stopColor={S.secondary} stopOpacity="0.25"/>
          <stop offset="1" stopColor={S.secondary} stopOpacity="0"/>
        </linearGradient>
      </defs>
      <path d={area} fill="url(#invGrad)"/>
      <path d={d} fill="none" stroke={S.secondary} strokeWidth="2.2" strokeLinecap="round" strokeLinejoin="round"/>
      <circle cx={xs[hi]} cy={ys[hi]} r="5" fill={S.secondary}/>
      <circle cx={xs[hi]} cy={ys[hi]} r="8" fill={S.secondary} fillOpacity="0.2"/>
      <g transform={`translate(${xs[hi] + 8}, ${ys[hi] - 12})`}>
        <rect width="56" height="18" rx="4" fill={S.primary}/>
        <text x="28" y="12" textAnchor="middle" fill="#fff" style={{ fontFamily: INTER, fontSize: 9, fontWeight: 700 }}>R$ 14.260</text>
      </g>
      {['ENE 23','ABR 23','JUL 23','OCT 23','HOY'].map((l, i) => (
        <text key={i} x={(i / 4) * w} y={h + 18} textAnchor={i === 0 ? 'start' : i === 4 ? 'end' : 'middle'}
          style={{ fontFamily: INTER, fontSize: 9, fill: S.onSurfaceFaint }}>{l}</text>
      ))}
    </svg>
  );
}

function MetricCard({ label, children, green }) {
  return (
    <div style={{ background: S.surfaceLowest, borderRadius: 16, padding: 14 }}>
      <div style={{ fontSize: 10, letterSpacing: 1, color: S.onSurfaceSoft, fontWeight: 700, textTransform: 'uppercase' }}>{label}</div>
      <div style={{ marginTop: 6 }}>{children}</div>
    </div>
  );
}

function ActRow({ icon, name, date, value, tag, positive }) {
  return (
    <div style={{ padding: '12px 0', display: 'flex', alignItems: 'center', gap: 12,
      borderTop: '1px solid rgba(195,198,207,0.25)' }}>
      <div style={{ width: 36, height: 36, borderRadius: 10, background: S.secondaryContainer,
        display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{icon}</div>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 13, fontWeight: 600 }}>{name}</div>
        <div style={{ fontSize: 10, letterSpacing: 0.8, color: S.onSurfaceSoft, fontWeight: 600, marginTop: 2 }}>{date}</div>
      </div>
      <div style={{ textAlign: 'right' }}>
        <BRLSmall value={value} size={13} weight={700} color={positive ? S.secondary : S.onSurface}/>
        <div style={{ fontSize: 9, letterSpacing: 0.8, color: S.onSurfaceSoft, fontWeight: 700, marginTop: 2 }}>{tag}</div>
      </div>
    </div>
  );
}

// ═════════════════════════════════════════════════════════════
// 06 · PORTAFOLIO / INVERTIR
// ═════════════════════════════════════════════════════════════
function ScreenPortafolio() {
  return (
    <Screen tab="Invertir">
      <div style={{ overflowY: 'auto', height: '100%', paddingBottom: 16 }}>
        <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between',
          padding: '4px 20px 12px' }}>
          <div style={{ fontFamily: MANROPE, fontSize: 20, fontWeight: 800, letterSpacing: -0.3 }}>Valora Pro</div>
          <div style={{ display: 'flex', gap: 18, alignItems: 'center' }}>
            <IcGlobe size={20} color={S.onSurface}/>
            <IcGear size={20} color={S.onSurface}/>
          </div>
        </div>

        <div style={{ margin: '0 16px 12px', borderRadius: 22, padding: '22px 22px',
          background: `linear-gradient(135deg, ${S.primaryContainer}, ${S.primary})`, color: '#fff', position: 'relative' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div style={{ fontSize: 10, letterSpacing: 1.8, fontWeight: 700, opacity: 0.65, textTransform: 'uppercase' }}>Total Consolidado</div>
            <IcWallet size={18} color="rgba(255,255,255,0.6)"/>
          </div>
          <div style={{ marginTop: 6 }}>
            <BRLBig value={248592.12} size={36} color="#fff" weight={800}/>
          </div>
          <div style={{ display: 'inline-flex', alignItems: 'center', gap: 4, marginTop: 8,
            fontSize: 13, fontWeight: 700, color: S.secondaryFixed }}>
            <IcTrendUp size={13} color={S.secondaryFixed}/> +12.4% <span style={{ color: 'rgba(255,255,255,0.5)', fontWeight: 500 }}>vs. último mes</span>
          </div>
          <div style={{ display: 'flex', gap: 8, marginTop: 18 }}>
            <StatPill label="CDI Bruto" value="112%"/>
            <StatPill label="Fee" value="0.2%"/>
            <StatPill label="Riesgo" value="Medio"/>
          </div>
        </div>

        {/* Asignación de Activos */}
        <div style={{ margin: '0 16px 12px', background: S.surfaceLowest, borderRadius: 20, padding: 18 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div>
              <div style={{ fontFamily: MANROPE, fontSize: 15, fontWeight: 700 }}>Asignación de Activos</div>
              <div style={{ fontSize: 11, color: S.onSurfaceSoft, marginTop: 2 }}>Distribución estratégica de la cartera</div>
            </div>
            <IcDots size={18} color={S.onSurfaceSoft}/>
          </div>
          <div style={{ display: 'flex', justifyContent: 'center', marginTop: 6 }}>
            <DonutChart
              cats={[
                { l: 'Renta Fija', pct: 60, c: S.secondary },
                { l: 'Acciones / FIIs', pct: 25, c: S.tertiary },
                { l: 'Cripto / Diversos', pct: 15, c: S.tertiaryFixed },
              ]}
              total={248592}
              centerLabel="Diversificada"
            />
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10, marginTop: 14 }}>
            <LegendRow color={S.secondary} label="Renta Fija" pct="60%"/>
            <LegendRow color={S.tertiary} label="Acciones / FIIs" pct="25%"/>
            <LegendRow color={S.tertiaryFixed} label="Cripto / Diversos" pct="15%"/>
          </div>
        </div>

        {/* Sugerencia IA */}
        <div style={{ margin: '0 16px 12px', background: S.secondaryContainer, borderRadius: 20, padding: 18,
          position: 'relative', overflow: 'hidden' }}>
          <IcSparkle size={18} color={S.secondary}/>
          <div style={{ fontFamily: MANROPE, fontSize: 15, fontWeight: 700, marginTop: 10 }}>Sugerencia IA</div>
          <div style={{ fontSize: 12, color: S.onSurfaceMuted, marginTop: 4, lineHeight: 1.5 }}>
            Su cartera tiene baja exposición en activos inmobiliarios. Considere FIIs de tijolo.
          </div>
          <button style={{ marginTop: 12, padding: '10px 16px', borderRadius: 12,
            background: S.secondary, color: '#fff', border: 'none',
            fontFamily: INTER, fontWeight: 700, fontSize: 13, cursor: 'pointer' }}>Explorar FIIs</button>
        </div>

        {/* Inversiones list */}
        <div style={{ padding: '8px 20px 0' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div>
              <div style={{ fontFamily: MANROPE, fontSize: 17, fontWeight: 800 }}>Inversiones</div>
              <div style={{ fontSize: 11, color: S.onSurfaceSoft }}>Detalle por activo</div>
            </div>
            <div style={{ display: 'flex', alignItems: 'center', gap: 4, fontSize: 12, fontWeight: 600, color: S.secondary }}>
              Ver Historial <IcChevR size={14} color={S.secondary}/>
            </div>
          </div>
          <InvRow icon={<IcTrendUp size={16} color={S.primaryContainer}/>} bg="#E3ECFA"
            name="Tesoro Selic 2029" tag="RENTA FIJA · POS-FIJADO" value={145230} pct="+0.88%"/>
          <InvRow icon={<IcBuilding size={16} color={S.secondary}/>} bg={S.secondaryContainer}
            name="KNRI11 · FII Kinea" tag="FII · LOGÍSTICA" value={42120.45} pct="+1.20%"/>
          <InvRow icon={<IcTrendUp size={16} color={S.tertiary}/>} bg="rgba(113,248,228,0.3)"
            name="CDB Inter 102% CDI" tag="RENTA FIJA · LIQUIDEZ DIARIA" value={61241.67} pct="+0.91%"/>
        </div>
      </div>
    </Screen>
  );
}

function StatPill({ label, value }) {
  return (
    <div style={{ flex: 1, background: 'rgba(0,0,0,0.25)', borderRadius: 99,
      padding: '8px 12px', textAlign: 'center' }}>
      <div style={{ fontSize: 9, letterSpacing: 1, fontWeight: 600, opacity: 0.65, textTransform: 'uppercase' }}>{label}</div>
      <div style={{ fontSize: 12, fontWeight: 700, marginTop: 2 }}>{value}</div>
    </div>
  );
}

function LegendRow({ color, label, pct }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <div style={{ width: 8, height: 8, borderRadius: 4, background: color }}/>
        <span style={{ fontSize: 13, color: S.onSurface }}>{label}</span>
      </div>
      <span style={{ fontSize: 13, fontWeight: 700, fontVariantNumeric: 'tabular-nums' }}>{pct}</span>
    </div>
  );
}

function InvRow({ icon, bg, name, tag, value, pct }) {
  return (
    <div style={{ marginTop: 10, background: S.surfaceLowest, borderRadius: 16, padding: '14px 16px',
      display: 'flex', gap: 14, alignItems: 'center' }}>
      <div style={{ width: 40, height: 40, borderRadius: 12, background: bg,
        display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{icon}</div>
      <div style={{ flex: 1 }}>
        <div style={{ fontSize: 14, fontWeight: 700 }}>{name}</div>
        <div style={{ fontSize: 9, letterSpacing: 0.8, fontWeight: 700, color: S.onSurfaceSoft,
          textTransform: 'uppercase', marginTop: 2 }}>{tag}</div>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline', marginTop: 8 }}>
          <div>
            <div style={{ fontSize: 9, color: S.onSurfaceFaint, letterSpacing: 0.5, fontWeight: 600 }}>SALDO ACTUAL</div>
            <BRLSmall value={value} size={13} weight={700}/>
          </div>
          <div>
            <div style={{ fontSize: 9, color: S.onSurfaceFaint, letterSpacing: 0.5, fontWeight: 600 }}>MES (NOV)</div>
            <div style={{ fontSize: 13, fontWeight: 700, color: S.secondary, textAlign: 'right' }}>{pct}</div>
          </div>
        </div>
      </div>
    </div>
  );
}

// Enhanced DonutChart accepting custom label
if (window.DonutChart) {
  // no-op, we'll shadow below
}
function DonutChartV2({ cats, centerLabel }) {
  const r = 72, stroke = 18, C = 2 * Math.PI * r;
  let acc = 0;
  return (
    <svg width="170" height="170" viewBox="0 0 180 180">
      <circle cx="90" cy="90" r={r} fill="none" stroke={S.surfaceLow} strokeWidth={stroke}/>
      {cats.map((c, i) => {
        const len = (c.pct / 100) * C;
        const off = -acc; acc += len;
        return <circle key={i} cx="90" cy="90" r={r} fill="none" stroke={c.c} strokeWidth={stroke}
          strokeDasharray={`${len} ${C}`} strokeDashoffset={off} transform="rotate(-90 90 90)"/>;
      })}
      <text x="90" y="96" textAnchor="middle" style={{ fontFamily: MANROPE, fontSize: 18, fill: S.onSurface, fontWeight: 800 }}>{centerLabel}</text>
    </svg>
  );
}
// monkey-patch DonutChart to support centerLabel
const _origDonut = window.DonutChart;
window.DonutChart = function DonutChart({ cats, centerLabel, total }) {
  if (centerLabel) return <DonutChartV2 cats={cats} centerLabel={centerLabel}/>;
  return _origDonut({ cats, total });
};

// ═════════════════════════════════════════════════════════════
// 07 · METAS Y PRESUPUESTO
// ═════════════════════════════════════════════════════════════
function ScreenMetas() {
  return (
    <Screen tab="Ajustes">
      <div style={{ overflowY: 'auto', height: '100%', paddingBottom: 16 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          padding: '4px 24px 18px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <Avatar/>
            <div style={{ fontFamily: MANROPE, fontSize: 20, fontWeight: 800 }}>Valora Pro</div>
          </div>
          <IcGear size={20} color={S.onSurface}/>
        </div>

        <div style={{ padding: '0 24px' }}>
          <div style={{ fontFamily: MANROPE, fontSize: 30, fontWeight: 800, letterSpacing: -0.7, lineHeight: 1.1 }}>
            Metas y<br/>Presupuesto
          </div>
          <div style={{ fontSize: 13, color: S.onSurfaceSoft, marginTop: 8 }}>
            Define tu santuario financiero. Equilibra ganancias y propósitos.
          </div>
        </div>

        {/* Salario */}
        <div style={{ margin: '18px 20px 0', background: S.surfaceLowest, borderRadius: 22, padding: 22 }}>
          <div style={{ fontSize: 10, letterSpacing: 1.5, fontWeight: 700, color: S.onSurfaceSoft, textTransform: 'uppercase' }}>Salario Líquido Mensual</div>
          <div style={{ marginTop: 8 }}>
            <BRLBig value={12500} size={38} weight={800}/>
          </div>
          <div style={{ display: 'flex', alignItems: 'center', gap: 6, marginTop: 10 }}>
            <div style={{ width: 6, height: 6, borderRadius: 3, background: S.secondary }}/>
            <span style={{ fontSize: 11, color: S.onSurfaceSoft }}>Base calculada tras deducciones fiscales automáticas.</span>
          </div>
        </div>

        {/* Beneficios Swile */}
        <div style={{ margin: '12px 20px 0', background: S.surfaceLowest, borderRadius: 22, padding: 22 }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
            <div style={{ width: 44, height: 44, borderRadius: 12, background: 'rgba(113,248,228,0.3)',
              display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <IcCup size={22} color={S.tertiary}/>
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ fontSize: 13, fontWeight: 600 }}>Beneficios Swile</div>
            </div>
            <BRLSmall value={1200} size={15} weight={700}/>
          </div>
          <div style={{ marginTop: 14, display: 'flex', justifyContent: 'space-between', padding: '10px 4px',
            borderTop: '1px solid rgba(195,198,207,0.25)' }}>
            <span style={{ fontSize: 13, color: S.onSurfaceSoft }}>Vale Comida</span>
            <BRLSmall value={800} size={13} weight={600}/>
          </div>
          <div style={{ display: 'flex', justifyContent: 'space-between', padding: '10px 4px' }}>
            <span style={{ fontSize: 13, color: S.onSurfaceSoft }}>Vale Alimentación</span>
            <BRLSmall value={400} size={13} weight={600}/>
          </div>
          <button style={{ marginTop: 10, width: '100%', padding: '13px', borderRadius: 14, border: 'none',
            background: `linear-gradient(135deg, ${S.primaryContainer}, ${S.primary})`, color: '#fff',
            fontFamily: INTER, fontSize: 13, fontWeight: 700, cursor: 'pointer' }}>Sincronizar Tarjeta Swile</button>
        </div>

        {/* Distribución Total — navy bar chart */}
        <div style={{ margin: '12px 20px 0', borderRadius: 22, padding: 22,
          background: `linear-gradient(135deg, ${S.primaryContainer}, ${S.primary})`, color: '#fff' }}>
          <div style={{ fontFamily: MANROPE, fontSize: 15, fontWeight: 700 }}>Distribución Total</div>
          <div style={{ display: 'flex', gap: 6, alignItems: 'flex-end', marginTop: 18, height: 70 }}>
            {[
              { l: 'Vivienda', h: 70, c: S.secondary },
              { l: 'Estilo', h: 42, c: S.tertiary },
              { l: 'Reserva', h: 58, c: S.secondaryFixed },
              { l: 'Libre', h: 36, c: '#B9A8FF' },
            ].map(b => (
              <div key={b.l} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8 }}>
                <div style={{ width: '100%', height: `${b.h}%`, background: b.c, borderRadius: '8px 8px 0 0' }}/>
                <span style={{ fontSize: 10, opacity: 0.7 }}>{b.l}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Asignación de Ingresos */}
        <div style={{ margin: '12px 20px 0', background: S.surfaceLowest, borderRadius: 22, padding: 22 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'baseline' }}>
            <div>
              <div style={{ fontFamily: MANROPE, fontSize: 16, fontWeight: 800 }}>Asignación de Ingresos</div>
              <div style={{ fontSize: 11, color: S.onSurfaceSoft, marginTop: 2 }}>Ajusta las partes de tu presupuesto ideal.</div>
            </div>
            <div style={{ textAlign: 'right' }}>
              <div style={{ fontFamily: MANROPE, fontSize: 22, fontWeight: 800, color: S.secondary }}>100%</div>
              <div style={{ fontSize: 9, color: S.onSurfaceSoft, letterSpacing: 0.8, fontWeight: 700 }}>ASIGNADO</div>
            </div>
          </div>

          <div style={{ marginTop: 18, display: 'flex', flexDirection: 'column', gap: 14 }}>
            <AllocRow icon={<IcHome size={16} color={S.primaryContainer}/>} label="Vivienda y Cuentas" pct={35} value={4375} note="REAL VS META" ideal="Ideal: Máximo 40%" barColor={S.secondary}/>
            <AllocRow icon={<IcCar size={16} color={S.primaryContainer}/>} label="Transporte y Movilidad" pct={15} value={1875} note="DOBLE LA META" ideal="Ideal: Máximo 15%" warn barColor={S.error}/>
            <AllocRow icon={<IcCup size={16} color={S.primaryContainer}/>} label="Ocio y Estilo de Vida" pct={20} value={2500} note="EL 5%" ideal="Ideal: Flexible" barColor={S.tertiary}/>
            <AllocRow icon={<IcTrendUp size={16} color={S.primaryContainer}/>} label="Inversiones y Reserva" pct={30} value={3750} note="CRECIMIENTO" ideal="Ideal: Mínimo 20%" barColor={S.secondary}/>
          </div>
        </div>

        <div style={{ padding: '16px 20px 0', display: 'flex', flexDirection: 'column', gap: 10 }}>
          <button style={{ width: '100%', height: 52, borderRadius: 16, border: 'none',
            background: `linear-gradient(135deg, ${S.primaryContainer}, ${S.primary})`, color: '#fff',
            fontFamily: INTER, fontWeight: 700, fontSize: 15, cursor: 'pointer' }}>Guardar Nuevo Presupuesto</button>
          <button style={{ width: '100%', height: 48, borderRadius: 16,
            background: 'transparent', color: S.onSurfaceSoft, border: 'none',
            fontFamily: INTER, fontWeight: 600, fontSize: 14, cursor: 'pointer' }}>Redefinir</button>
        </div>
      </div>
    </Screen>
  );
}

function AllocRow({ icon, label, pct, value, note, ideal, warn, barColor }) {
  return (
    <div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
        <div style={{ width: 32, height: 32, borderRadius: 10, background: S.surfaceLow,
          display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{icon}</div>
        <div style={{ flex: 1 }}>
          <div style={{ fontSize: 13, fontWeight: 600 }}>{label}</div>
          <div style={{ fontSize: 10, color: warn ? S.error : S.onSurfaceFaint, fontWeight: 700, letterSpacing: 0.5, textTransform: 'uppercase', marginTop: 2 }}>{note}</div>
        </div>
        <div style={{ textAlign: 'right' }}>
          <div style={{ fontFamily: MANROPE, fontSize: 15, fontWeight: 800 }}>{pct}%</div>
          <div style={{ fontSize: 10, color: S.onSurfaceSoft, fontVariantNumeric: 'tabular-nums' }}>R$ {value.toLocaleString('pt-BR')}</div>
        </div>
      </div>
      <div style={{ marginTop: 8, marginLeft: 42, height: 4, background: S.surfaceLow, borderRadius: 2, overflow: 'hidden' }}>
        <div style={{ width: `${pct * 2}%`, height: '100%', background: barColor, borderRadius: 2 }}/>
      </div>
      <div style={{ fontSize: 10, color: S.onSurfaceFaint, marginTop: 4, marginLeft: 42 }}>{ideal}</div>
    </div>
  );
}

// ═════════════════════════════════════════════════════════════
// 08 · NOTIFICACIONES
// ═════════════════════════════════════════════════════════════
function ScreenNotif() {
  return (
    <Screen tab="Ajustes">
      <div style={{ overflowY: 'auto', height: '100%', paddingBottom: 16 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center',
          padding: '4px 24px 14px' }}>
          <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
            <Avatar/>
            <div style={{ fontFamily: MANROPE, fontSize: 18, fontWeight: 800 }}>Sanctuario</div>
          </div>
          <IcBell size={22} color={S.onSurface}/>
        </div>

        <div style={{ padding: '0 24px' }}>
          <div style={{ fontFamily: MANROPE, fontSize: 30, fontWeight: 800, letterSpacing: -0.7 }}>Notificaciones</div>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginTop: 6 }}>
            <div style={{ fontSize: 13, color: S.onSurfaceSoft, maxWidth: 200, lineHeight: 1.4 }}>Gestiona tus alertas financieras</div>
            <div style={{ fontSize: 13, fontWeight: 600, color: S.secondary, textAlign: 'right', maxWidth: 110, lineHeight: 1.3 }}>Marcar todo como leído</div>
          </div>
        </div>

        {/* Alertas Críticas */}
        <CategoryLabel label="Alertas Críticas" color={S.error}/>
        <NotifCard accent={S.error}
          icon={<IcAlert size={20} color={S.error}/>} iconBg={S.errorSoft}
          time="Hace 2h"
          title="Budget Alert: 90% of Housing budget used"
          body="Has alcanzado el límite crítico de tu presupuesto mensual para vivienda. Evita gastos adicionales en esta categoría."/>

        <CategoryLabel label="Consejos de IA" color={S.secondary}/>
        <NotifCard accent={S.secondary}
          icon={<IcBulb size={20} color={S.secondary}/>} iconBg={S.secondaryContainer}
          time="Hace 5h"
          title="Investment Tip: Rebalance recommended"
          body="Your liquidity is high, consider rebalancing. Nuestra IA detectó una oportunidad de diversificación en fondos ESG."
          cta="Ver estrategia"/>

        <CategoryLabel label="Actualizaciones" color={S.tertiary}/>
        <NotifCard
          icon={<IcDoc size={20} color={S.onSurfaceMuted}/>} iconBg={S.surfaceDim}
          time="Ayer"
          title="Monthly Report ready for download"
          body="Tu resumen de rendimiento de Octubre ya está disponible. Revisa tus hitos financieros del mes."/>
        <NotifCard
          icon={<IcShield size={20} color={S.onSurfaceMuted}/>} iconBg={S.surfaceDim}
          time="Hace 2 días"
          title="Nueva política de privacidad"
          body="Hemos actualizado nuestros términos para mejorar la seguridad de tus activos digitales."/>

        <div style={{ textAlign: 'center', padding: '32px 0 8px', color: S.onSurfaceFaint }}>
          <IcCheck size={24} color={S.onSurfaceFaint}/>
          <div style={{ fontSize: 12, color: S.onSurfaceFaint, marginTop: 8 }}>Estás al día con tus finanzas</div>
        </div>
      </div>
    </Screen>
  );
}

function CategoryLabel({ label, color }) {
  return (
    <div style={{ padding: '20px 24px 8px' }}>
      <span style={{ display: 'inline-block', padding: '4px 12px', borderRadius: 99,
        background: `${color}15`, color, fontSize: 10, fontWeight: 700, letterSpacing: 1.2, textTransform: 'uppercase' }}>{label}</span>
    </div>
  );
}

function NotifCard({ icon, iconBg, title, body, time, accent, cta }) {
  return (
    <div style={{ margin: '0 20px 10px', background: S.surfaceLowest, borderRadius: 16,
      padding: '16px 18px', display: 'flex', gap: 14, position: 'relative', overflow: 'hidden' }}>
      {accent && <div style={{ position: 'absolute', left: 0, top: 10, bottom: 10, width: 3,
        background: accent, borderRadius: '0 2px 2px 0' }}/>}
      <div style={{ width: 40, height: 40, borderRadius: 12, background: iconBg,
        display: 'flex', alignItems: 'center', justifyContent: 'center', flexShrink: 0 }}>{icon}</div>
      <div style={{ flex: 1, minWidth: 0 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 8 }}>
          <div style={{ fontSize: 14, fontWeight: 700, lineHeight: 1.3, flex: 1 }}>{title}</div>
          <div style={{ fontSize: 10, color: S.onSurfaceFaint, flexShrink: 0, marginTop: 2 }}>{time}</div>
        </div>
        <div style={{ fontSize: 12, color: S.onSurfaceSoft, marginTop: 6, lineHeight: 1.5 }}>{body}</div>
        {cta && <div style={{ marginTop: 10, fontSize: 13, fontWeight: 700, color: S.secondary,
          display: 'inline-flex', alignItems: 'center', gap: 4 }}>
          {cta} <IcChevR size={13} color={S.secondary}/>
        </div>}
      </div>
    </div>
  );
}

Object.assign(window, { ScreenInversion, ScreenPortafolio, ScreenMetas, ScreenNotif });
