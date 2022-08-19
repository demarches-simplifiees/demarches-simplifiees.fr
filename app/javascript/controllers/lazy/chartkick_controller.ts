import { Controller } from '@hotwired/stimulus';
import { toggle, delegate } from '@utils';
import Highcharts from 'highcharts';
import Chartkick from 'chartkick';

export class ChartkickController extends Controller {
  async connect() {
    delegate('click', '[data-toggle-chart]', (event) =>
      toggleChart(event as MouseEvent)
    );
  }
}

Chartkick.use(Highcharts);
function reflow(nextChartId?: string) {
  nextChartId && Chartkick.charts[nextChartId]?.getChartObject()?.reflow();
}

function toggleChart(event: MouseEvent) {
  const nextSelectorItem = event.target as HTMLButtonElement,
    chartClass = nextSelectorItem.dataset.toggleChart,
    nextChart = chartClass
      ? document.querySelector<HTMLDivElement>(chartClass)
      : undefined,
    nextChartId = nextChart?.children[0]?.id,
    currentSelectorItem = nextSelectorItem.parentElement?.querySelector(
      '.segmented-control-item-active'
    ),
    currentChart =
      nextSelectorItem.parentElement?.parentElement?.querySelector<HTMLDivElement>(
        '.chart:not(.hidden)'
      );

  // Change the current selector and the next selector states
  currentSelectorItem?.classList.toggle('segmented-control-item-active');
  nextSelectorItem.classList.toggle('segmented-control-item-active');

  // Hide the currently shown chart and show the new one
  currentChart && toggle(currentChart);
  nextChart && toggle(nextChart);

  // Reflow needed, see https://github.com/highcharts/highcharts/issues/1979
  reflow(nextChartId);
}
