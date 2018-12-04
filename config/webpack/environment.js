const path = require('path');
const { environment } = require('@rails/webpacker');

const resolve = {
  alias: {
    '@utils': path.resolve(__dirname, '..', '..', 'app/javascript/shared/utils')
  }
};

environment.config.merge({ resolve });

module.exports = environment;
