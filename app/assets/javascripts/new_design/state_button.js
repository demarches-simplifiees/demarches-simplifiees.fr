TPS.showMotivation = function (state) {
  $(".motivation." + state).show();
  $(".dropdown-items").hide();
};

TPS.motivationCancel = function () {
  $(".motivation").hide();
  $(".dropdown-items").show();
};
