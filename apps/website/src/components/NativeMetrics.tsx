import * as m from '@/integrations/i18n/paraglide/messages'

export function NativeMetrics() {
  const metrics = [
    { value: m.metric1Value(), label: m.metric1Label(), sub: m.metric1Sub() },
    { value: m.metric2Value(), label: m.metric2Label(), sub: m.metric2Sub() },
    { value: m.metric3Value(), label: m.metric3Label(), sub: m.metric3Sub() },
    { value: m.metric4Value(), label: m.metric4Label(), sub: m.metric4Sub() },
  ]

  return (
    <section className="metrics-section" data-reveal>
      <div className="container">
        <div className="metrics-grid">
          {metrics.map((metric, idx) => (
            <div key={idx} className="metric-card">
              <div className="metric-value">{metric.value}</div>
              <div className="metric-label">{metric.label}</div>
              <div className="metric-sub">{metric.sub}</div>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
