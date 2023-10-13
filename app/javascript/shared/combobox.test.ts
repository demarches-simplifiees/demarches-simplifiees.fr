import { suite, test, beforeEach, expect } from 'vitest';
import { matchSorter } from 'match-sorter';

import { Combobox, Option, State } from './combobox';

suite('Combobox', () => {
  const options: Option[] =
    'Fraises,Myrtilles,Framboises,Mûres,Canneberges,Groseilles,Baies de sureau,Mûres blanches,Baies de genièvre,Baies d’açaï'
      .split(',')
      .map((label) => ({ label, value: label }));

  let combobox: Combobox;
  let currentState: State;

  suite('single select without custom value', () => {
    suite('with default selection', () => {
      beforeEach(() => {
        combobox = new Combobox({
          options,
          selected: options.at(0) ?? null,
          render: (state) => {
            currentState = state;
          }
        });
        combobox.init();
      });

      test('open select box and select option with click', () => {
        expect(currentState.open).toBeFalsy();
        expect(currentState.loading).toBe(null);
        expect(currentState.selection?.label).toBe('Fraises');

        combobox.open();
        expect(currentState.open).toBeTruthy();

        combobox.select('Mûres');
        expect(currentState.selection?.label).toBe('Mûres');
        expect(currentState.open).toBeFalsy();
      });

      test('open select box and select option with enter', () => {
        expect(currentState.open).toBeFalsy();
        expect(currentState.selection?.label).toBe('Fraises');

        combobox.keyboard('ArrowDown');
        expect(currentState.open).toBeTruthy();
        expect(currentState.selection?.label).toBe('Fraises');
        expect(currentState.focused?.label).toBe('Fraises');

        combobox.keyboard('ArrowDown');
        expect(currentState.selection?.label).toBe('Fraises');
        expect(currentState.focused?.label).toBe('Myrtilles');

        combobox.keyboard('Enter');
        expect(currentState.selection?.label).toBe('Myrtilles');
        expect(currentState.open).toBeFalsy();

        combobox.keyboard('Enter');
        expect(currentState.selection?.label).toBe('Myrtilles');
        expect(currentState.open).toBeFalsy();
      });

      test('open select box and select option with tab', () => {
        combobox.keyboard('ArrowDown');
        combobox.keyboard('ArrowDown');

        combobox.keyboard('Tab');
        expect(currentState.selection?.label).toBe('Myrtilles');
        expect(currentState.open).toBeFalsy();
        expect(currentState.hint).toEqual({
          type: 'selected',
          label: 'Myrtilles'
        });
      });

      test('do not open select box on focus', () => {
        combobox.focus();
        expect(currentState.open).toBeFalsy();
      });
    });

    suite('empty', () => {
      beforeEach(() => {
        combobox = new Combobox({
          options,
          selected: null,
          render: (state) => {
            currentState = state;
          }
        });
        combobox.init();
      });

      test('open select box on focus', () => {
        combobox.focus();
        expect(currentState.open).toBeTruthy();
      });

      suite('open', () => {
        beforeEach(() => {
          combobox.open();
        });

        test('if tab on empty input nothing is selected', () => {
          expect(currentState.open).toBeTruthy();
          expect(currentState.selection).toBeNull();
          combobox.keyboard('Tab');

          expect(currentState.open).toBeFalsy();
          expect(currentState.selection).toBeNull();
        });

        test('if enter on empty input nothing is selected', () => {
          expect(currentState.open).toBeTruthy();
          expect(currentState.selection).toBeNull();

          combobox.keyboard('Enter');
          expect(currentState.open).toBeFalsy();
          expect(currentState.selection).toBeNull();
        });
      });

      suite('closed', () => {
        test('if tab on empty input nothing is selected', () => {
          expect(currentState.open).toBeFalsy();
          expect(currentState.selection).toBeNull();

          combobox.keyboard('Tab');
          expect(currentState.open).toBeFalsy();
          expect(currentState.selection).toBeNull();
        });

        test('if enter on empty input nothing is selected', () => {
          expect(currentState.open).toBeFalsy();
          expect(currentState.selection).toBeNull();

          combobox.keyboard('Enter');
          expect(currentState.open).toBeFalsy();
          expect(currentState.selection).toBeNull();
        });
      });

      test('type exact match and press enter', () => {
        combobox.input('Baies');
        expect(currentState.open).toBeTruthy();
        expect(currentState.selection).toBeNull();
        expect(currentState.options.length).toEqual(3);

        combobox.keyboard('Enter');
        expect(currentState.open).toBeFalsy();
        expect(currentState.selection?.label).toBe('Baies d’açaï');
      });

      test('type exact match and press tab', () => {
        combobox.input('Baies');
        expect(currentState.open).toBeTruthy();
        expect(currentState.selection).toBeNull();

        combobox.keyboard('Tab');
        expect(currentState.open).toBeFalsy();
        expect(currentState.selection?.label).toBe('Baies d’açaï');
        expect(currentState.inputValue).toEqual('Baies d’açaï');
      });

      test('type non matching input and press enter', () => {
        combobox.input('toto');
        expect(currentState.open).toBeFalsy();
        expect(currentState.selection).toBeNull();

        combobox.keyboard('Enter');
        expect(currentState.open).toBeFalsy();
        expect(currentState.selection).toBeNull();
        expect(currentState.inputValue).toEqual('');
      });

      test('type non matching input and press tab', () => {
        combobox.input('toto');
        expect(currentState.open).toBeFalsy();
        expect(currentState.selection).toBeNull();

        combobox.keyboard('Tab');
        expect(currentState.open).toBeFalsy();
        expect(currentState.selection).toBeNull();
        expect(currentState.inputValue).toEqual('');
      });

      test('type non matching input and close', () => {
        combobox.input('toto');
        expect(currentState.open).toBeFalsy();
        expect(currentState.selection).toBeNull();

        combobox.close();
        expect(currentState.open).toBeFalsy();
        expect(currentState.selection).toBeNull();
        expect(currentState.inputValue).toEqual('');
      });

      test('focus should circle', () => {
        combobox.input('Baie');
        expect(currentState.open).toBeTruthy();
        expect(currentState.options.map(({ label }) => label)).toEqual([
          'Baies d’açaï',
          'Baies de genièvre',
          'Baies de sureau'
        ]);
        expect(currentState.focused).toBeNull();
        combobox.keyboard('ArrowDown');
        expect(currentState.focused?.label).toBe('Baies d’açaï');
        combobox.keyboard('ArrowDown');
        expect(currentState.focused?.label).toBe('Baies de genièvre');
        combobox.keyboard('ArrowDown');
        expect(currentState.focused?.label).toBe('Baies de sureau');
        combobox.keyboard('ArrowDown');
        expect(currentState.focused?.label).toBe('Baies d’açaï');
        combobox.keyboard('ArrowUp');
        expect(currentState.focused?.label).toBe('Baies de sureau');
      });
    });
  });

  suite('single select with custom value', () => {
    beforeEach(() => {
      combobox = new Combobox({
        options,
        selected: null,
        allowsCustomValue: true,
        render: (state) => {
          currentState = state;
        }
      });
      combobox.init();
    });

    test('type non matching input and press enter', () => {
      combobox.input('toto');
      expect(currentState.open).toBeFalsy();
      expect(currentState.selection).toBeNull();

      combobox.keyboard('Enter');
      expect(currentState.open).toBeFalsy();
      expect(currentState.selection).toBeNull();
      expect(currentState.inputValue).toEqual('toto');
    });

    test('type non matching input and press tab', () => {
      combobox.input('toto');
      expect(currentState.open).toBeFalsy();
      expect(currentState.selection).toBeNull();

      combobox.keyboard('Tab');
      expect(currentState.open).toBeFalsy();
      expect(currentState.selection).toBeNull();
      expect(currentState.inputValue).toEqual('toto');
    });

    test('type non matching input and close', () => {
      combobox.input('toto');
      expect(currentState.open).toBeFalsy();
      expect(currentState.selection).toBeNull();

      combobox.close();
      expect(currentState.open).toBeFalsy();
      expect(currentState.selection).toBeNull();
      expect(currentState.inputValue).toEqual('toto');
    });
  });

  suite('single select with fetcher', () => {
    beforeEach(() => {
      combobox = new Combobox({
        options: (term: string) =>
          Promise.resolve(matchSorter(options, term, { keys: ['value'] })),
        selected: null,
        render: (state) => {
          currentState = state;
        }
      });
      combobox.init();
    });

    test('type and get options from fetcher', async () => {
      expect(currentState.open).toBeFalsy();
      expect(currentState.loading).toBe(false);

      const result = combobox.input('Baies');

      expect(currentState.loading).toBe(true);
      await result;
      expect(currentState.loading).toBe(false);
      expect(currentState.open).toBeTruthy();
      expect(currentState.selection).toBeNull();
      expect(currentState.options.length).toEqual(3);
    });
  });
});
