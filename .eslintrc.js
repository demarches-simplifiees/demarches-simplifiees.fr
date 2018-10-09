module.exports = {
  root: true,
  parserOptions: {
    ecmaVersion: 2018,
    sourceType: 'module'
  },
  globals: {
    'process': true
  },
  plugins: ['prettier'],
  extends: ['eslint:recommended', 'prettier'],
  env: {
    browser: true
  },
  rules: {
    'prettier/prettier': 'error'
  },
  overrides: [
    {
      files: ['config/webpack/*.js'],
      env: {
        node: true
      }
    }
  ]
};
