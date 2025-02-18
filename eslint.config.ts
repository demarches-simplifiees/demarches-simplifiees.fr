import eslint from '@eslint/js';
import eslintPluginPrettierRecommended from 'eslint-plugin-prettier/recommended';
import eslintPluginReact from 'eslint-plugin-react';
import eslintPluginReactHooks from 'eslint-plugin-react-hooks';
import globals from 'globals';
import tseslint from 'typescript-eslint';

export default tseslint.config(
  eslint.configs.recommended,
  tseslint.configs.recommended,
  eslintPluginPrettierRecommended,
  {
    rules: {
      '@typescript-eslint/no-explicit-any': 'error',
      '@typescript-eslint/no-unused-vars': 'error'
    }
  },
  {
    files: ['app/javascript/components/**/*.{ts,tsx,js,jsx}'],
    ...eslintPluginReact.configs.flat.recommended,
    ...eslintPluginReact.configs.flat['jsx-runtime']
  },
  {
    files: ['app/javascript/components/**/*.{ts,tsx,js,jsx}'],
    plugins: { 'react-hooks': eslintPluginReactHooks },
    rules: {
      ...eslintPluginReactHooks.configs.recommended.rules,
      'react/prop-types': 'off',
      'react-hooks/exhaustive-deps': 'error'
    }
  },
  {
    files: ['app/javascript/**/*.{ts,tsx,js,jsx}'],
    languageOptions: { globals: { ...globals.browser } }
  },
  {
    files: ['*.config.{ts,js}'],
    languageOptions: { globals: { ...globals.node } }
  }
);
