process.env.NODE_ENV = process.env.NODE_ENV || 'production';

const environment = require('./environment');

// https://github.com/rails/webpacker/issues/1235
environment.config.optimization.minimizer[0].options.uglifyOptions.ecma = 5; // for IE 11 support
environment.config.optimization.minimizer[0].options.uglifyOptions.safari10 = true;

module.exports = environment.toWebpackConfig();
