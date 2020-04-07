const path = require('path');
const { environment } = require('@rails/webpacker');

const resolve = {
  alias: {
    '@utils': path.resolve(__dirname, '..', '..', 'app/javascript/shared/utils')
  }
};

environment.splitChunks();
environment.config.merge({ resolve });

// Uncoment next lines to run webpack-bundle-analyzer
// const { BundleAnalyzerPlugin } = require('webpack-bundle-analyzer');
// environment.plugins.append('BundleAnalyzer', new BundleAnalyzerPlugin());

module.exports = environment;
