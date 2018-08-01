module.exports = {
  root: true,
  parserOptions: {
    ecmaVersion: 2017,
    sourceType: 'module'
  },
  globals: {
    '$': true,
    'process': true
  },
  plugins: ['prettier'],
  extends: ['eslint:recommended', 'prettier'],
  env: {
    browser: true
  },
  rules: {
    'prettier/prettier': 'error'
  }
};
