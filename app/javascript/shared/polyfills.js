// Include runtime-polyfills for older browsers.
// Due to babel.config.js's 'useBuiltIns', only polyfills actually
// required by the browsers we support will be included.
import '@babel/polyfill';
import 'dom4';
