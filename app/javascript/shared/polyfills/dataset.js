/*
  @preserve dataset polyfill for IE < 11. See https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement/dataset and http://caniuse.com/#search=dataset

  @author ShirtlessKirk copyright 2015
  @license WTFPL (http://www.wtfpl.net/txt/copying)
*/

const dash = /-([a-z])/gi;
const dataRegEx = /^data-(.+)/;
const hasEventListener = !!document.addEventListener;
const test = document.createElement('_');
const DOMAttrModified = 'DOMAttrModified';

let mutationSupport = false;

function clearDataset(event) {
  delete event.target._datasetCache;
}

function toCamelCase(string) {
  return string.replace(dash, function (_, letter) {
    return letter.toUpperCase();
  });
}

function getDataset() {
  const dataset = {};

  for (let attribute of this.attributes) {
    let match = attribute.name.match(dataRegEx);
    if (match) {
      dataset[toCamelCase(match[1])] = attribute.value;
    }
  }

  return dataset;
}

function mutation() {
  if (hasEventListener) {
    test.removeEventListener(DOMAttrModified, mutation, false);
  } else {
    test.detachEvent(`on${DOMAttrModified}`, mutation);
  }

  mutationSupport = true;
}

if (!test.dataset) {
  if (hasEventListener) {
    test.addEventListener(DOMAttrModified, mutation, false);
  } else {
    test.attachEvent(`on${DOMAttrModified}`, mutation);
  }

  // trigger event (if supported)
  test.setAttribute('foo', 'bar');

  Object.defineProperty(Element.prototype, 'dataset', {
    get: mutationSupport
      ? function get() {
          if (!this._datasetCache) {
            this._datasetCache = getDataset.call(this);
          }

          return this._datasetCache;
        }
      : getDataset
  });

  if (mutationSupport && hasEventListener) {
    // < IE9 supports neither
    document.addEventListener(DOMAttrModified, clearDataset, false);
  }
}
