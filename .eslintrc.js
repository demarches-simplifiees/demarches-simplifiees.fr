module.exports = {
  root: true,
  parserOptions: {
    ecmaVersion: 2017,
    sourceType: 'module'
  },
  globals: {
    'process': true
  },
  plugins: ['prettier'],
  extends: ['eslint:recommended', 'prettier'],
  env: {
    es6: true,
    browser: true
  },
  rules: {
    'prettier/prettier': 'error'
  },
  overrides: [
    {
      files: ['config/webpack/**/*.js'],
      env: {
        node: true
      }
    }
  ]
};
