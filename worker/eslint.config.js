// @ts-check
import js from '@eslint/js';
import { defineConfig, globalIgnores } from 'eslint/config';
import tseslint from 'typescript-eslint';

// 06 §6.3: strictTypeChecked + stylisticTypeChecked, no-console (use the Logger
// dep), no-floating-promises as an error.
export default defineConfig(
  globalIgnores(['node_modules/', 'dist/', 'coverage/', '.wrangler/', 'worker-configuration.d.ts']),
  js.configs.recommended,
  tseslint.configs.strictTypeChecked,
  tseslint.configs.stylisticTypeChecked,
  {
    languageOptions: {
      parserOptions: {
        project: ['./tsconfig.json', './tsconfig.node.json'],
        tsconfigRootDir: import.meta.dirname,
      },
    },
    rules: {
      'no-console': 'error',
      '@typescript-eslint/no-floating-promises': 'error',
    },
  },
);
