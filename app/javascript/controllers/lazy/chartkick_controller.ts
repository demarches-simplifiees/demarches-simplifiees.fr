import { Controller } from '@hotwired/stimulus';
import Chartkick from 'chartkick';
import Highcharts from 'highcharts';
import invariant from 'tiny-invariant';

Chartkick.use(Highcharts);

export default class ChartkickController extends Controller {
  static targets = ['chart'];

  declare readonly chartTargets: HTMLElement[];

  toggleChart(event: Event) {
    const target = event.currentTarget as HTMLInputElement;
    const chartClass = target.dataset.toggleChart;

    invariant(chartClass, 'Missing data-toggle-chart attribute');

    const nextChart = document.querySelector(chartClass);
    const currentChart = this.chartTargets.find(
      (chart) => !chart.classList.contains('hidden')
    );

    if (currentChart) {
      currentChart.classList.add('hidden');
    }

    if (nextChart) {
      nextChart.classList.remove('hidden');
      const nextChartId = nextChart.children[0]?.id;
      this.reflow(nextChartId);
    }
  }

  reflow(chartId: string) {
    if (chartId) {
      const chart = Chartkick.charts[chartId];
      if (chart) {
        chart.getChartObject()?.reflow();
      }
    }
  }
}
