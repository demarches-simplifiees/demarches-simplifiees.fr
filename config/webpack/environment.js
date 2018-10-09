const path = require('path');
const { environment } = require('@rails/webpacker');

// By default don't transpile JS files in ./node_modules – except for some specific modules.
const babelLoader = environment.loaders.get('babel');
babelLoader.exclude = function(modulePath) {
  let forcedModules = [
    'activestorage' // ActiveStorage uses 'class', which is not supported by IE 11 and older Safari version
  ];
  return (
    modulePath.includes('node_modules') &&
    forcedModules.every(
      forcedModule => !modulePath.includes('node_modules/' + forcedModule)
    )
  );
};

const resolve = {
  alias: {
    '@utils': path.resolve(__dirname, '..', '..', 'app/javascript/shared/utils')
  }
};

environment.config.merge({ resolve });

module.exports = environment;
