const path = require('path');
const { environment } = require('@rails/webpacker');

const resolve = {
  alias: {
    '@utils': path.resolve(__dirname, '..', '..', 'app/javascript/shared/utils')
  }
};

environment.splitChunks();
environment.config.merge({ resolve });
environment.loaders.get(
  'nodeModules'
).exclude = /(?:@?babel(?:\/|\\{1,2}|-).+)|regenerator-runtime|core-js|^webpack$|^webpack-assets-manifest$|^webpack-cli$|^webpack-sources$|^@rails\/webpacker$|^mapbox-gl$|/;

// Uncoment next lines to run webpack-bundle-analyzer
// const { BundleAnalyzerPlugin } = require('webpack-bundle-analyzer');
// environment.plugins.append('BundleAnalyzer', new BundleAnalyzerPlugin());

module.exports = environment;
