// Include runtime-polyfills for older browsers.
// Due to babel.config.js's 'useBuiltIns', only polyfills actually
// required by the browsers we support will be included.
import 'core-js/stable';
import 'regenerator-runtime/runtime';
import 'dom4';
import 'intersection-observer';
import 'whatwg-fetch';
import '@webcomponents/custom-elements';
import '@webcomponents/template';
import '@stimulus/polyfills';
import 'formdata-polyfill';
import 'event-target-polyfill';
import 'yet-another-abortcontroller-polyfill';

import './polyfills/insertAdjacentElement';
import './polyfills/dataset';

// IE 11 has no baseURI (required by turbo)
if (document.baseURI == undefined) {
  document.baseURI = document.URL;
}

// IE 11 has no children on DocumentFragment (required by turbo)
function polyfillChildren(proto) {
  Object.defineProperty(proto, 'children', {
    get: function () {
      const children = [];
      for (const node of this.childNodes) {
        if (node.nodeType == 1) {
          children.push(node);
        }
      }
      return children;
    }
  });
}

const fragment = document.createDocumentFragment();
if (fragment.children == undefined) {
  polyfillChildren(DocumentFragment.prototype);
}
