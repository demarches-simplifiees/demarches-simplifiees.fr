/*
  Updated w/ insertAdjacentElement
  @author Dan Levy @justsml
  2016-06-23

  Credit: @lyleunderwood - afterend patch/fix

  2011-10-10

  By Eli Grey, http://eligrey.com
  Public Domain.
  NO WARRANTY EXPRESSED OR IMPLIED. USE AT YOUR OWN RISK.
*/

function insertAdjacentElement(position, elem) {
  const _this = this;
  const parent = this.parentNode;
  let node, first;

  switch (position.toLowerCase()) {
    case 'beforebegin':
      while ((node = elem.firstChild)) {
        parent.insertBefore(node, _this);
      }
      break;
    case 'afterbegin':
      first = _this.firstChild;
      while ((node = elem.lastChild)) {
        first = _this.insertBefore(node, first);
      }
      break;
    case 'beforeend':
      while ((node = elem.firstChild)) {
        _this.appendChild(node);
      }
      break;
    case 'afterend':
      parent.insertBefore(elem, _this.nextSibling);
      break;
  }
  return elem;
}

// Method missing in Firefox < 48
if (!HTMLElement.prototype.insertAdjacentElement) {
  HTMLElement.prototype.insertAdjacentElement = insertAdjacentElement;
}
