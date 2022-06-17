import { defineConfig } from 'vite';
import ViteReact from '@vitejs/plugin-react';
import ViteLegacy from '@vitejs/plugin-legacy';
import FullReload from 'vite-plugin-full-reload';
import RubyPlugin from 'vite-plugin-ruby';

export default defineConfig({
  resolve: { alias: { '@utils': '/shared/utils.ts' } },
  build: {
    sourcemap: true,
    rollupOptions: {
      output: {
        manualChunks(id) {
          if (id.match('maplibre') || id.match('mapbox')) {
            return 'maplibre';
          }
        }
      }
    }
  },
  plugins: [
    RubyPlugin(),
    ViteReact({
      parserPlugins: ['classProperties', 'classPrivateProperties'],
      jsxRuntime: 'classic'
    }),
    FullReload(['config/routes.rb', 'app/views/**/*'], { delay: 200 }),
    ViteLegacy({
      targets: [
        'defaults',
        'Chrome >= 50',
        'Edge >= 14',
        'Firefox >= 50',
        'Opera >= 40',
        'Safari >= 8',
        'iOS >= 8',
        'IE >= 11'
      ],
      additionalLegacyPolyfills: [
        '@stimulus/polyfills',
        '@webcomponents/custom-elements',
        '@webcomponents/template',
        'event-target-polyfill',
        'formdata-polyfill',
        'intersection-observer',
        'regenerator-runtime/runtime',
        'whatwg-fetch',
        'yet-another-abortcontroller-polyfill'
      ]
    })
  ]
});
