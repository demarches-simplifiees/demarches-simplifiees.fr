const path = require('path');
const webpack = require('webpack');

module.exports = {
  mode: 'production',
  devtool: 'source-map',
  entry: {
    application: './app/javascript/application.js',
    manager: './app/javascript/manager.js',
    track: './app/javascript/track.js',
    'track-admin': './app/javascript/track-admin.js'
  },
  resolve: {
    extensions: ['.js', '.mjs', '.jsx'],
    alias: {
      '@utils': path.resolve(__dirname, 'app/javascript/shared/utils')
    }
  },
  module: {
    rules: [
      {
        test: /\.(js|mjs|jsx)$/,
        type: 'javascript/auto',
        resolve: {
          fullySpecified: false
        },
        exclude: /node_modules/,
        use: {
          loader: 'babel-loader',
          options: {
            presets: [
              [
                '@babel/preset-env',
                {
                  forceAllTransforms: true,
                  useBuiltIns: 'usage',
                  corejs: 3,
                  modules: false,
                  exclude: ['transform-typeof-symbol']
                }
              ],
              [
                '@babel/preset-react',
                {
                  useBuiltIns: true
                }
              ]
            ],
            plugins: [
              'babel-plugin-macros',
              '@babel/plugin-syntax-dynamic-import',
              '@babel/plugin-transform-destructuring',
              [
                '@babel/plugin-proposal-class-properties',
                {
                  loose: true
                }
              ],
              [
                '@babel/plugin-proposal-object-rest-spread',
                {
                  useBuiltIns: true
                }
              ],
              [
                '@babel/plugin-proposal-private-methods',
                {
                  loose: true
                }
              ],
              [
                '@babel/plugin-proposal-private-property-in-object',
                {
                  loose: true
                }
              ],
              [
                '@babel/plugin-transform-runtime',
                {
                  helpers: false,
                  regenerator: true
                }
              ],
              [
                '@babel/plugin-transform-regenerator',
                {
                  async: false
                }
              ]
            ]
            // [
            //   'babel-plugin-transform-react-remove-prop-types',
            //   {
            //     removeImport: true
            //   }
            // ]
          }
        }
      },
      {
        test: /\.css$/,
        use: [{ loader: 'style-loader' }, { loader: 'css-loader' }]
      }
    ]
  },
  output: {
    filename: '[name].js',
    sourceMapFilename: '[name].js.map',
    path: path.resolve(__dirname, 'app/assets/builds')
  },
  plugins: [
    new webpack.optimize.LimitChunkCountPlugin({
      maxChunks: 1
    })
  ]
};
