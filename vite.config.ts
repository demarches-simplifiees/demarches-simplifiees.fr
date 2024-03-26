import { defineConfig } from 'vite';
import ViteReact from '@vitejs/plugin-react';
import RubyPlugin from 'vite-plugin-ruby';

const plugins = [RubyPlugin(), ViteReact({ jsxRuntime: 'classic' })];

export default defineConfig({
  resolve: { alias: { '@utils': '/shared/utils.ts' } },
  build: { sourcemap: true },
  plugins
});
