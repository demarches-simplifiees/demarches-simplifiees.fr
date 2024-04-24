import { defineConfig } from 'vite';
import ViteReact from '@vitejs/plugin-react';
import ViteLegacy from '@vitejs/plugin-legacy';
import FullReload from 'vite-plugin-full-reload';
import RubyPlugin from 'vite-plugin-ruby';

const plugins = [
  RubyPlugin(),
  ViteReact({ jsxRuntime: 'classic' }),
  FullReload(
    ['config/routes.rb', 'app/views/**/*', 'app/components/**/*.haml'],
    { delay: 200 }
  )
];

if (shouldBuildLegacy()) {
  plugins.push(
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
        'dom4',
        'core-js/stable',
        '@stimulus/polyfills',
        'turbo-polyfills',
        'intersection-observer',
        'regenerator-runtime/runtime',
        'whatwg-fetch',
        'yet-another-abortcontroller-polyfill'
      ]
    })
  );
}

export default defineConfig({
  resolve: { alias: { '@utils': '/shared/utils.ts' } },
  build: { sourcemap: true },
  plugins
});

function shouldBuildLegacy() {
  if (process.env.VITE_LEGACY == 'disabled') {
    return false;
  }
  return (
    process.env.RAILS_ENV == 'production' ||
    process.env.VITE_LEGACY == 'enabled'
  );
}
