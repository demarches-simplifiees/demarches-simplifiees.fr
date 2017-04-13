var TPS = TPS || {};

TPS.toggleChart = function(event, chartClass) {
  var nextSelectorItem = $(event.target),
      nextChart = $(chartClass),
      nextChartId = nextChart.children().first().attr("id"),
      currentSelectorItem = nextSelectorItem.parent().find(".segmented-control-item-active"),
      currentChart = nextSelectorItem.parent().parent().find(".chart:not(.hidden)");

  // Change the current selector and the next selector states
  currentSelectorItem.toggleClass("segmented-control-item-active");
  nextSelectorItem.toggleClass("segmented-control-item-active");

  // Hide the currently shown chart and show the new one
  currentChart.toggleClass("hidden");
  nextChart.toggleClass("hidden");

  // Reflow needed, see https://github.com/highcharts/highcharts/issues/1979
  Chartkick.charts[nextChartId].getChartObject().reflow();
}
