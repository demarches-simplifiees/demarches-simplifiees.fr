import React, {
  useMemo,
  useState,
  useRef,
  useContext,
  createContext,
  useId,
  ReactNode,
  ChangeEventHandler,
  KeyboardEventHandler
} from 'react';
import {
  Combobox,
  ComboboxInput,
  ComboboxList,
  ComboboxOption,
  ComboboxPopover
} from '@reach/combobox';
import '@reach/combobox/styles.css';
import { matchSorter } from 'match-sorter';
import { XIcon } from '@heroicons/react/outline';
import isHotkey from 'is-hotkey';
import invariant from 'tiny-invariant';

import { useDeferredSubmit, useHiddenField } from './shared/hooks';

const Context = createContext<{
  onRemove: (value: string) => void;
} | null>(null);

type Option = [label: string, value: string];

function isOptions(options: string[] | Option[]): options is Option[] {
  return Array.isArray(options[0]);
}

const optionLabelByValue = (
  values: string[],
  options: Option[],
  value: string
): string => {
  const maybeOption: Option | undefined = values.includes(value)
    ? [value, value]
    : options.find(([, optionValue]) => optionValue == value);
  return maybeOption ? maybeOption[0] : '';
};

export type ComboMultipleProps = {
  options: string[] | Option[];
  id: string;
  labelledby: string;
  describedby: string;
  label: string;
  group: string;
  name?: string;
  selected: string[];
  acceptNewValues?: boolean;
};

export default function ComboMultiple({
  options,
  id,
  labelledby,
  describedby,
  label,
  group,
  name = 'value',
  selected,
  acceptNewValues = false
}: ComboMultipleProps) {
  invariant(id || label, 'ComboMultiple: `id` or a `label` are required');
  invariant(group, 'ComboMultiple: `group` is required');

  const inputRef = useRef<HTMLInputElement>(null);
  const [term, setTerm] = useState('');
  const [selections, setSelections] = useState(selected);
  const [newValues, setNewValues] = useState<string[]>([]);
  const internalId = useId();
  const inputId = id ?? internalId;
  const removedLabelledby = `${inputId}-remove`;
  const selectedLabelledby = `${inputId}-selected`;

  const optionsWithLabels = useMemo<Option[]>(
    () =>
      isOptions(options)
        ? options
        : options.filter((o) => o).map((o) => [o, o]),
    [options]
  );

  const extraOptions = useMemo(
    () =>
      acceptNewValues &&
      term &&
      term.length > 2 &&
      !optionLabelByValue(newValues, optionsWithLabels, term)
        ? [[term, term]]
        : [],
    [acceptNewValues, term, optionsWithLabels, newValues]
  );

  const extraListOptions = useMemo(
    () =>
      acceptNewValues && term && term.length > 2 && term.includes(';')
        ? term.split(';').map((val) => [val.trim(), val.trim()])
        : [],
    [acceptNewValues, term]
  );

  const results = useMemo(
    () =>
      [
        ...extraOptions,
        ...(term
          ? matchSorter(
              optionsWithLabels.filter(([label]) => !label.startsWith('--')),
              term
            )
          : optionsWithLabels)
      ].filter(([, value]) => !selections.includes(value)),
    [term, selections, extraOptions, optionsWithLabels]
  );
  const [, setHiddenFieldValue, hiddenField] = useHiddenField(group, name);
  const awaitFormSubmit = useDeferredSubmit(hiddenField);

  const handleChange: ChangeEventHandler<HTMLInputElement> = (event) => {
    setTerm(event.target.value);
  };

  const saveSelection = (fn: (selections: string[]) => string[]) => {
    setSelections((selections) => {
      selections = fn(selections);
      setHiddenFieldValue(JSON.stringify(selections));
      return selections;
    });
  };

  const onSelect = (value: string) => {
    const maybeValue = [...extraOptions, ...optionsWithLabels].find(
      ([, val]) => val == value
    );

    const maybeValueFromListOptions = extraListOptions.find(
      ([, val]) => val == value
    );

    const selectedValue =
      term.includes(';') && acceptNewValues
        ? maybeValueFromListOptions && maybeValueFromListOptions[1]
        : maybeValue && maybeValue[1];

    if (selectedValue) {
      if (
        (acceptNewValues &&
          extraOptions[0] &&
          extraOptions[0][0] == selectedValue) ||
        (acceptNewValues && extraListOptions[0])
      ) {
        setNewValues((newValues) => {
          const set = new Set(newValues);
          set.add(selectedValue);
          return [...set];
        });
      }
      saveSelection((selections) => {
        const set = new Set(selections);
        set.add(selectedValue);
        return [...set];
      });
    }
    setTerm('');
    awaitFormSubmit.done();
    hidePopover();
  };

  const onRemove = (optionValue: string) => {
    if (optionValue) {
      saveSelection((selections) =>
        selections.filter((value) => value != optionValue)
      );
      setNewValues((newValues) =>
        newValues.filter((value) => value != optionValue)
      );
    }
    inputRef.current?.focus();
  };

  const onKeyDown: KeyboardEventHandler<HTMLInputElement> = (event) => {
    if (
      isHotkey('enter', event) ||
      isHotkey(' ', event) ||
      isHotkey(',', event) ||
      isHotkey(';', event)
    ) {
      if (term.includes(';')) {
        for (const val of term.split(';')) {
          event.preventDefault();
          onSelect(val.trim());
        }
      } else if (
        term &&
        [...extraOptions, ...optionsWithLabels]
          .map(([label]) => label)
          .includes(term)
      ) {
        event.preventDefault();
        onSelect(term);
      }
    }
  };

  const hidePopover = () => {
    document
      .querySelector(`[data-reach-combobox-popover-id="${inputId}"]`)
      ?.setAttribute('hidden', 'true');
  };

  const showPopover = () => {
    document
      .querySelector(`[data-reach-combobox-popover-id="${inputId}"]`)
      ?.removeAttribute('hidden');
  };

  const onBlur = () => {
    const shouldSelect =
      term &&
      [...extraOptions, ...optionsWithLabels]
        .map(([label]) => label)
        .includes(term);

    awaitFormSubmit(() => {
      if (term.includes(';')) {
        for (const val of term.split(';')) {
          onSelect(val.trim());
        }
      } else if (shouldSelect) {
        onSelect(term);
      } else {
        hidePopover();
      }
    });
  };

  return (
    <Combobox openOnFocus={true} onSelect={onSelect}>
      <ComboboxTokenLabel onRemove={onRemove}>
        <span id={removedLabelledby} className="hidden">
          désélectionner
        </span>
        <ul
          id={selectedLabelledby}
          aria-live="polite"
          aria-atomic={true}
          data-reach-combobox-token-list
        >
          {selections.map((selection) => (
            <ComboboxToken
              key={selection}
              value={selection}
              describedby={removedLabelledby}
            >
              {optionLabelByValue(newValues, optionsWithLabels, selection)}
            </ComboboxToken>
          ))}
        </ul>
        <ComboboxInput
          ref={inputRef}
          value={term}
          onChange={handleChange}
          onKeyDown={onKeyDown}
          onBlur={onBlur}
          onClick={showPopover}
          autocomplete={false}
          id={inputId}
          aria-label={label}
          aria-labelledby={[labelledby, selectedLabelledby]
            .filter(Boolean)
            .join(' ')}
          aria-describedby={describedby}
        />
      </ComboboxTokenLabel>
      {results && (results.length > 0 || !acceptNewValues) && (
        <ComboboxPopover
          className="shadow-popup"
          data-reach-combobox-popover-id={inputId}
        >
          <ComboboxList>
            {results.length === 0 && (
              <li data-reach-combobox-no-results>
                Aucun résultat{' '}
                <button
                  onClick={() => {
                    setTerm('');
                    inputRef.current?.focus();
                  }}
                  className="button"
                >
                  Effacer
                </button>
              </li>
            )}
            {results.map(([label, value], index) => {
              if (label.startsWith('--')) {
                return <ComboboxSeparator key={index} value={label} />;
              }
              return (
                <ComboboxOption key={index} value={value}>
                  {label}
                </ComboboxOption>
              );
            })}
          </ComboboxList>
        </ComboboxPopover>
      )}
    </Combobox>
  );
}

function ComboboxTokenLabel({
  onRemove,
  children
}: {
  onRemove: (value: string) => void;
  children: ReactNode;
}) {
  return (
    <Context.Provider value={{ onRemove }}>
      <div data-reach-combobox-token-label>{children}</div>
    </Context.Provider>
  );
}

function ComboboxSeparator({ value }: { value: string }) {
  return (
    <li aria-disabled="true" role="option" data-reach-combobox-separator>
      {value.slice(2, -2)}
    </li>
  );
}

function ComboboxToken({
  value,
  describedby,
  children,
  ...props
}: {
  value: string;
  describedby: string;
  children: ReactNode;
}) {
  const context = useContext(Context);
  invariant(context, 'invalid context');
  const { onRemove } = context;

  return (
    <li data-reach-combobox-token {...props}>
      <button
        type="button"
        onClick={() => {
          onRemove(value);
        }}
        onKeyDown={(event) => {
          if (event.key === 'Backspace') {
            onRemove(value);
          }
        }}
        aria-describedby={describedby}
      >
        <XIcon className="icon-size mr-1" aria-hidden="true" />
        {children}
      </button>
    </li>
  );
}
