import Chartkick from 'chartkick';
import { toggle } from '@utils';

export function toggleChart(event, chartClass) {
  const nextSelectorItem = event.target,
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
