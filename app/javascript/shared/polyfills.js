// Include runtime-polyfills for older browsers.
// Due to babel.config.js's 'useBuiltIns', only polyfills actually
// required by the browsers we support will be included.
import '@babel/polyfill';
import 'dom4';
import './polyfills/insertAdjacentElement';
import './polyfills/dataset';

if (typeof window.IntersectionObserver === 'undefined') {
  import('intersection-observer');
}
