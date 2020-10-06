// Ruby chartkick helper implementation assumes Chartkick is already loaded.
// It has no way to delay execution. So we wrap all the Chartkick classes
// to queue rendering for when Chartkick is loaded.

class AreaChart {
  constructor(...args) {
    charts.add(['AreaChart', args]);
  }
}

class PieChart {
  constructor(...args) {
    charts.add(['PieChart', args]);
  }
}

class LineChart {
  constructor(...args) {
    charts.add(['LineChart', args]);
  }
}

class ColumnChart {
  constructor(...args) {
    charts.add(['ColumnChart', args]);
  }
}

const charts = new Set();

function initialize() {
  for (const [ChartType, args] of charts) {
    new window.Chartkick[ChartType](...args);
  }
  charts.clear();
}

if (!window.Chartkick) {
  window.Chartkick = { AreaChart, PieChart, LineChart, ColumnChart };
  addEventListener('chartkick:ready', initialize);
}
