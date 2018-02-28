DS.showMotivation = function (state) {
  $(".motivation." + state).show();
  $(".dropdown-items").hide();
};

DS.motivationCancel = function () {
  $(".motivation").hide();
  $(".dropdown-items").show();
};
