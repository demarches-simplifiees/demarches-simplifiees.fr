document.addEventListener('turbolinks:load', function() {
  var masters, i, master, slave, slaveOptions;

  masters = document.querySelectorAll('select[data-slave-options]');
  for (i = 0; i < masters.length; i++) {
    master = masters[i];
    slave = document.querySelector('select[data-slave-id="' + master.dataset.masterId + '"]');
    slaveOptions = JSON.parse(master.dataset.slaveOptions);

    master.addEventListener('change', function(e) {
      var option, options, element;

      while ((option = slave.firstChild)) {
        slave.removeChild(option);
      }

      options = slaveOptions[e.target.value];

      for (i = 0; i < options.length; i++) {
        option = options[i];
        element = document.createElement("option");
        element.textContent = option;
        element.value = option;
        slave.appendChild(element);
      }

      slave.selectedIndex = 0;
    });
  }
});
