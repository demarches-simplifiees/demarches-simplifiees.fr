const path = require('path');
const alias = require('esbuild-plugin-alias');

// TODO: add sourcemaps
// TODO: ensure we use the production build of react in production
// TODO: ensure browser support is correct
// TODO: ensure JS gets built before CI and before tests
// TODO: check for application.js size regression

require('esbuild')
  .build({
    entryPoints: ['application.js', 'manager.js', 'track.js', 'track-admin.js'],
    bundle: true,
    outdir: path.join(process.cwd(), 'app/assets/builds'),
    absWorkingDir: path.join(process.cwd(), 'app/javascript'),
    watch: process.argv.includes('--watch'),
    plugins: [
      alias({
        '@utils': path.resolve(__dirname, 'app/javascript/shared/utils.js'),
        // Workaround for https://github.com/alex3165/react-mapbox-gl/issues/822
        'react-mapbox-gl': path.resolve(
          __dirname,
          'node_modules/react-mapbox-gl/lib/index.js'
        )
      })
    ],
    minify: process.argv.includes('--minify')
  })
  .catch(() => process.exit(1));
