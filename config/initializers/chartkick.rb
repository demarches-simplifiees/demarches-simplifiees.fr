Chartkick.options = {
  content_for: :charts_js,
  colors: ["var(--background-action-high-blue-france)"],
  thousands: ' ',
  decimal: ',',
  default_library_config: {
    chart: { backgroundColor: 'var(--background-contrast-grey)' },
             xAxis: {
               lineColor: 'var(--border-action-high-grey)',
                      labels: { style: { color: "var(--text-default-grey)" } }
             },
             yAxis: {
               gridLineColor: 'var(--border-plain-grey)',
                      lineColor: 'var(--border-action-high-grey)',
                      labels: { style: { color: "var(--text-default-grey)" } }
             }
  }
}
