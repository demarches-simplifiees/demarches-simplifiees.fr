import { defineConfig } from 'vite';
import ViteReact from '@vitejs/plugin-react';
import RubyPlugin from 'vite-plugin-ruby';
import FullReload from 'vite-plugin-full-reload';

const plugins = [
  RubyPlugin(),
  ViteReact({ jsxRuntime: 'classic' }),
  FullReload(
    ['config/routes.rb', 'app/views/**/*', 'app/components/**/*.haml'],
    { delay: 200 }
  )
];

export default defineConfig({
  resolve: { alias: { '@utils': '/shared/utils.ts' } },
  build: { sourcemap: true, assetsInlineLimit: 0 },
  plugins
});
