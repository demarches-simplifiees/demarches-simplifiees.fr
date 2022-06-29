import './polyfills/dataset';
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

// IE 11 has no isConnected on Node
function polyfillIsConnected(proto) {
  Object.defineProperty(proto, 'isConnected', {
    get: function () {
      return document.documentElement.contains(this);
    }
  });
}

if (!('isConnected' in Node.prototype)) {
  polyfillIsConnected(Node.prototype);
}
