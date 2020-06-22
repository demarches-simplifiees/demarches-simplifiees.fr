// Include runtime-polyfills for older browsers.
// Due to babel.config.js's 'useBuiltIns', only polyfills actually
// required by the browsers we support will be included.
import 'core-js/stable';
import 'regenerator-runtime/runtime';
import 'dom4';
import 'intersection-observer';

import './polyfills/insertAdjacentElement';
import './polyfills/dataset';
