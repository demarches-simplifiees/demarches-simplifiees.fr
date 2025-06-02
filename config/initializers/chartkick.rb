# frozen_string_literal: true

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
    },
    legend: {
      itemStyle: {
        color: "var(--text-default-grey)"
      }
    },
    plotOptions: {
      pie: {
        dataLabels: {
          color: "var(--text-default-grey)",
          enabled: true, format: '{point.name} : {point.percentage: .1f}%',
          style: {
            textOutline: 'none'
          }
        }
      }
    }
  }
}
