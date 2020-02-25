import Chartkick from 'chartkick';
import Highcharts from 'highcharts';
import { toggle, delegate } from '@utils';

export default function() {
  return null;
}

function toggleChart(event) {
  const nextSelectorItem = event.target,
    chartClass = event.target.dataset.toggleChart,
    nextChart = document.querySelector(chartClass),
    nextChartId = nextChart.children[0].id,
    currentSelectorItem = nextSelectorItem.parentElement.querySelector(
      '.segmented-control-item-active'
    ),
    currentChart = nextSelectorItem.parentElement.parentElement.querySelector(
      '.chart:not(.hidden)'
    );

  // Change the current selector and the next selector states
  currentSelectorItem.classList.toggle('segmented-control-item-active');
  nextSelectorItem.classList.toggle('segmented-control-item-active');

  // Hide the currently shown chart and show the new one
  toggle(currentChart);
  toggle(nextChart);

  // Reflow needed, see https://github.com/highcharts/highcharts/issues/1979
  Chartkick.charts[nextChartId].getChartObject().reflow();
}

delegate('click', '[data-toggle-chart]', toggleChart);

Chartkick.use(Highcharts);
window.Chartkick = Chartkick;
