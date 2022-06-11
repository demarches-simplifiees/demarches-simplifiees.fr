module.exports = {
  root: true,
  parser: '@typescript-eslint/parser',
  globals: {
    process: true,
    gon: true
  },
  plugins: ['prettier', 'react-hooks'],
  extends: [
    'eslint:recommended',
    'prettier',
    'plugin:react/recommended',
    'plugin:react-hooks/recommended'
  ],
  env: {
    es6: true,
    browser: true
  },
  rules: {
    'prettier/prettier': 'error',
    'react-hooks/rules-of-hooks': 'error',
    'react-hooks/exhaustive-deps': 'error',
    'react/prop-types': 'off'
  },
  settings: {
    react: { version: 'detect' }
  },
  overrides: [
    {
      files: [
        '.eslintrc.js',
        'vite.config.ts',
        'tailwind.config.js',
        'postcss.config.js'
      ],
      env: { node: true }
    },
    {
      files: ['**/*.ts', '**/*.tsx'],
      plugins: ['@typescript-eslint'],
      extends: [
        'eslint:recommended',
        'plugin:@typescript-eslint/recommended',
        'plugin:react-hooks/recommended',
        'prettier'
      ],
      rules: {
        'prettier/prettier': 'error',
        'react-hooks/rules-of-hooks': 'error',
        'react-hooks/exhaustive-deps': 'error',
        '@typescript-eslint/no-explicit-any': 'error',
        '@typescript-eslint/no-unused-vars': 'error'
      }
    }
  ]
};
