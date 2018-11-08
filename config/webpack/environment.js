const path = require('path');
const { environment } = require('@rails/webpacker');
const { VueLoaderPlugin } = require('vue-loader');
const vue = require('./loaders/vue');

const resolve = {
  alias: {
    '@utils': path.resolve(__dirname, '..', '..', 'app/javascript/shared/utils')
  }
};

environment.config.merge({ resolve });

environment.plugins.append('VueLoaderPlugin', new VueLoaderPlugin());
environment.loaders.append('vue', vue);
module.exports = environment;
