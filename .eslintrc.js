module.exports = {
  root: true,
  parser: 'babel-eslint',
  parserOptions: {
    ecmaVersion: 2017,
    sourceType: 'module'
  },
  globals: {
    'process': true,
    'gon': true
  },
  plugins: ['prettier', 'react-hooks'],
  extends: ['eslint:recommended', 'prettier', 'plugin:react/recommended'],
  env: {
    es6: true,
    browser: true
  },
  rules: {
    'prettier/prettier': 'error',
    'react-hooks/rules-of-hooks': 'error'
  },
  settings: {
    react: {
      version: 'detect'
    }
  },
  overrides: [
    {
      files: ['config/webpack/**/*.js', 'babel.config.js', 'postcss.config.js'],
      env: {
        node: true
      }
    }
  ]
};
