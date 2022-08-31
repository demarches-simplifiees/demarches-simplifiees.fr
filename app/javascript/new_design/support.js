//
// This content is inspired by w3c aria example, rewritten for better RGAA compatibility.
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

    this.radioInput = this.domNode.querySelector('input[type="radio"]');

    this.hideContent();

    this.domNode.addEventListener('keydown', this.handleKeydown.bind(this));
    this.domNode.addEventListener('click', this.handleClick.bind(this));
  }

  showContent() {
    this.radioInput.checked = true;

    if (this.controlledNode) {
      this.controlledNode.setAttribute('aria-hidden', 'false');
      this.controlledNode.classList.remove('hidden');
    }

    this.allButtons.forEach((b) => {
      if (b != this) {
        b.hideContent();
      }
    });
  }

  hideContent() {
    this.radioInput.checked = false;

    if (this.controlledNode) {
      this.controlledNode.setAttribute('aria-hidden', 'true');
      this.controlledNode.classList.add('hidden');
    }
  }

  toggleExpand() {
    if (
      this.controlledNode &&
      this.controlledNode.getAttribute('aria-hidden') === 'true'
    ) {
      this.showContent();
    } else {
      this.hideContent();
    }
  }

  setAllButtons(buttons) {
    this.allButtons = buttons;
  }

  handleKeydown(event) {
    switch (event.keyCode) {
      case this.keyCode.RETURN:
        this.showContent();

        event.stopPropagation();
        event.preventDefault();
        break;

      default:
        break;
    }
  }

  handleClick() {
    // NOTE: click event is also fired on input and label activations
    // ie., not necessarily by a mouse click but any user inputs, like keyboard navigation with arrows keys.
    // Cf https://www.w3.org/TR/2012/WD-html5-20121025/content-models.html#interactive-content

    this.showContent();
  }
}

/* Initialize Hide/Show Buttons */

if (document.querySelector('#contact-form')) {
  window.addEventListener(
    'DOMContentLoaded',
    function () {
      var buttons = document.querySelectorAll('fieldset[name=type] label');
      var expandButtons = [];

      buttons.forEach((button) => {
        var be = new ButtonExpand(button);
        expandButtons.push(be);
      });
      expandButtons.forEach((button) => button.setAllButtons(expandButtons));
    },
    false
  );
}
