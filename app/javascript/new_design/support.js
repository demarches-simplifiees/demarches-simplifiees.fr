//
// This content is inspired by w3c aria example
// https://www.w3.org/TR/wai-aria-practices-1.1/examples/disclosure/disclosure-faq.html
//

var ButtonExpand = function (domNode) {
  this.domNode = domNode;

  this.keyCode = Object.freeze({
    RETURN: 13
  });
};

ButtonExpand.prototype.init = function () {
  this.allButtons = [];
  this.controlledNode = false;

  var id = this.domNode.getAttribute('aria-controls');

  if (id) {
    this.controlledNode = document.getElementById(id);
  }

  this.domNode.setAttribute('aria-expanded', 'false');
  this.hideContent();

  this.domNode.addEventListener('keydown', this.handleKeydown.bind(this));
  this.domNode.addEventListener('click', this.handleClick.bind(this));
  this.domNode.addEventListener('focus', this.handleFocus.bind(this));
  this.domNode.addEventListener('blur', this.handleBlur.bind(this));
};

ButtonExpand.prototype.showContent = function () {
  this.domNode.setAttribute('aria-expanded', 'true');
  this.domNode.classList.add('primary');
  if (this.controlledNode) {
    this.controlledNode.classList.remove('hidden');
  }
  this.formInput.value = this.domNode.getAttribute('data-question-type');

  this.allButtons.forEach((b) => {
    if (b != this) {
      b.hideContent();
    }
  });
};

ButtonExpand.prototype.hideContent = function () {
  this.domNode.setAttribute('aria-expanded', 'false');
  this.domNode.classList.remove('primary');
  if (this.controlledNode) {
    this.controlledNode.classList.add('hidden');
  }
};

ButtonExpand.prototype.toggleExpand = function () {
  if (this.domNode.getAttribute('aria-expanded') === 'true') {
    this.hideContent();
  } else {
    this.showContent();
  }
};

ButtonExpand.prototype.setAllButtons = function (buttons) {
  this.allButtons = buttons;
};

ButtonExpand.prototype.setFormInput = function (formInput) {
  this.formInput = formInput;
};

/* EVENT HANDLERS */

ButtonExpand.prototype.handleKeydown = function (event) {
  switch (event.keyCode) {
    case this.keyCode.RETURN:
      this.toggleExpand();

      event.stopPropagation();
      event.preventDefault();
      break;

    default:
      break;
  }
};

ButtonExpand.prototype.handleClick = function (event) {
  event.stopPropagation();
  event.preventDefault();
  this.toggleExpand();
};

ButtonExpand.prototype.handleFocus = function () {
  this.domNode.classList.add('focus');
};

ButtonExpand.prototype.handleBlur = function () {
  this.domNode.classList.remove('focus');
};

/* Initialize Hide/Show Buttons */

window.addEventListener(
  'load',
  function () {
    var buttons = document.querySelectorAll(
      'button[aria-expanded][aria-controls], button.button-without-hint'
    );
    var expandButtons = [];
    var formInput = document.querySelector('form input#type');

    buttons.forEach((button) => {
      var be = new ButtonExpand(button);
      be.init();
      expandButtons.push(be);
    });
    expandButtons.forEach((button) => button.setAllButtons(expandButtons));
    expandButtons.forEach((button) => button.setFormInput(formInput));
  },
  false
);
