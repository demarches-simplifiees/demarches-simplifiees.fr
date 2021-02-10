import reactRefresh from '@vitejs/plugin-react-refresh';
import legacy from '@vitejs/plugin-legacy';
import RubyPlugin from 'vite-plugin-ruby';
import { defineConfig } from 'vite';

export default defineConfig({
  alias: {
    '@utils': '~/shared/utils.js'
  },
  plugins: [
    RubyPlugin(),
    reactRefresh({
      parserPlugins: ['classProperties', 'classPrivateProperties']
    }),
    legacy({
      targets: ['defaults', 'IE >= 11']
    })
  ],
  build: {
    sourcemap: true
  }
});
