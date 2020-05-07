const path = require('path');
const { environment } = require('@rails/webpacker');

const resolve = {
  alias: {
    '@utils': path.resolve(__dirname, '..', '..', 'app/javascript/shared/utils')
  }
};

environment.splitChunks();
environment.config.merge({ resolve });

// Excluding node_modules From Being Transpiled By Babel-Loader
// One change to take into consideration,
// is that Webpacker 4 transpiles the node_modules folder with the babel-loader.
// This folder used to be ignored by Webpacker 3.
// The new behavior helps in case some library contains ES6 code, but in some cases it can lead to issues.
// To avoid running babel-loader in the node_modules folder, replicating the same behavior as Webpacker 3,
// we added the following code:

const nodeModulesLoader = environment.loaders.get('nodeModules');
if (!Array.isArray(nodeModulesLoader.exclude)) {
  nodeModulesLoader.exclude =
    nodeModulesLoader.exclude == null ? [] : [nodeModulesLoader.exclude];
}
nodeModulesLoader.exclude.push(/mapbox-gl/);

// Uncoment next lines to run webpack-bundle-analyzer
// const { BundleAnalyzerPlugin } = require('webpack-bundle-analyzer');
// environment.plugins.append('BundleAnalyzer', new BundleAnalyzerPlugin());

module.exports = environment;
