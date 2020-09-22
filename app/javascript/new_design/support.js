//
// This content is inspired by w3c aria example
// https://www.w3.org/TR/wai-aria-practices-1.1/examples/disclosure/disclosure-faq.html
//

class ButtonExpand {
  constructor(domNode) {
    this.domNode = domNode;

    this.keyCode = Object.freeze({
      RETURN: 13
    });

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
  }

  showContent() {
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
  }

  hideContent() {
    this.domNode.setAttribute('aria-expanded', 'false');
    this.domNode.classList.remove('primary');
    if (this.controlledNode) {
      this.controlledNode.classList.add('hidden');
    }
  }

  toggleExpand() {
    if (this.domNode.getAttribute('aria-expanded') === 'true') {
      this.hideContent();
    } else {
      this.showContent();
    }
  }

  setAllButtons(buttons) {
    this.allButtons = buttons;
  }

  setFormInput(formInput) {
    this.formInput = formInput;
  }

  handleKeydown() {
    switch (event.keyCode) {
      case this.keyCode.RETURN:
        this.toggleExpand();

        event.stopPropagation();
        event.preventDefault();
        break;

      default:
        break;
    }
  }

  handleClick() {
    event.stopPropagation();
    event.preventDefault();
    this.toggleExpand();
  }

  handleFocus = function () {
    this.domNode.classList.add('focus');
  };

  handleBlur() {
    this.domNode.classList.remove('focus');
  }
}

/* Initialize Hide/Show Buttons */

if (document.querySelector('#contact-form')) {
  window.addEventListener(
    'ds:page:update',
    function () {
      var buttons = document.querySelectorAll(
        'button[aria-expanded][aria-controls], button.button-without-hint'
      );
      var expandButtons = [];
      var formInput = document.querySelector('form input#type');

      buttons.forEach((button) => {
        var be = new ButtonExpand(button);
        expandButtons.push(be);
      });
      expandButtons.forEach((button) => button.setAllButtons(expandButtons));
      expandButtons.forEach((button) => button.setFormInput(formInput));
    },
    false
  );
}
