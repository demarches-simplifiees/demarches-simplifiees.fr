import React, {
  useMemo,
  useState,
  useRef,
  useContext,
  createContext,
  useEffect,
  useLayoutEffect
} from 'react';
import PropTypes from 'prop-types';
import {
  Combobox,
  ComboboxInput,
  ComboboxList,
  ComboboxOption,
  ComboboxPopover
} from '@reach/combobox';
import '@reach/combobox/styles.css';
import { matchSorter } from 'match-sorter';
import { fire } from '@utils';
import { XIcon } from '@heroicons/react/outline';
import isHotkey from 'is-hotkey';

import { useDeferredSubmit } from './shared/hooks';

const Context = createContext();

function ComboMultipleDropdownList({
  options,
  hiddenFieldId,
  selected,
  label,
  acceptNewValues = false
}) {
  if (label == undefined) {
    label = 'Choisir une option';
  }
  if (!Array.isArray(options[0])) {
    options = options.filter((o) => o).map((o) => [o, o]);
  }
  const inputRef = useRef();
  const [term, setTerm] = useState('');
  const [selections, setSelections] = useState(selected);
  const [newValues, setNewValues] = useState([]);

  const optionValueByLabel = (label) => {
    const maybeOption = newValues.includes(label)
      ? [label, label]
      : options.find(([optionLabel]) => optionLabel == label);
    return maybeOption ? maybeOption[1] : undefined;
  };
  const optionLabelByValue = (value) => {
    const maybeOption = newValues.includes(value)
      ? [value, value]
      : options.find(([, optionValue]) => optionValue == value);
    return maybeOption ? maybeOption[0] : undefined;
  };

  const extraOptions = useMemo(
    () =>
      acceptNewValues && term && term.length > 2 && !optionLabelByValue(term)
        ? [[term, term]]
        : [],
    [acceptNewValues, term, newValues.join(',')]
  );
  const results = useMemo(
    () =>
      [
        ...extraOptions,
        ...(term
          ? matchSorter(
              options.filter(([label]) => !label.startsWith('--')),
              term
            )
          : options)
      ].filter(([, value]) => !selections.includes(value)),
    [term, selections.join(','), newValues.join(',')]
  );
  const hiddenField = useMemo(
    () => document.querySelector(`input[data-uuid="${hiddenFieldId}"]`),
    [hiddenFieldId]
  );
  const awaitFormSubmit = useDeferredSubmit(hiddenField);

  const handleChange = (event) => {
    setTerm(event.target.value);
  };

  const saveSelection = (fn) => {
    setSelections((selections) => {
      selections = fn(selections);
      if (hiddenField) {
        hiddenField.setAttribute('value', JSON.stringify(selections));
        fire(hiddenField, 'autosave:trigger');
      }
      return selections;
    });
  };

  const onSelect = (value) => {
    const maybeValue = [...extraOptions, ...options].find(
      ([val]) => val == value
    );
    const selectedValue = maybeValue && maybeValue[1];
    if (selectedValue) {
      if (
        acceptNewValues &&
        extraOptions[0] &&
        extraOptions[0][0] == selectedValue
      ) {
        setNewValues((newValues) => [...newValues, selectedValue]);
      }
      saveSelection((selections) => [...selections, selectedValue]);
    }
    setTerm('');
    awaitFormSubmit.done();
  };

  const onRemove = (label) => {
    const optionValue = optionValueByLabel(label);
    if (optionValue) {
      saveSelection((selections) =>
        selections.filter((value) => value != optionValue)
      );
      setNewValues((newValues) =>
        newValues.filter((value) => value != optionValue)
      );
    }
    inputRef.current.focus();
  };

  const onKeyDown = (event) => {
    if (
      isHotkey('enter', event) ||
      isHotkey(' ', event) ||
      isHotkey(',', event) ||
      isHotkey(';', event)
    ) {
      if (
        term &&
        [...extraOptions, ...options].map(([label]) => label).includes(term)
      ) {
        event.preventDefault();
        onSelect(term);
      }
    }
  };

  const onBlur = () => {
    if (
      term &&
      [...extraOptions, ...options].map(([label]) => label).includes(term)
    ) {
      awaitFormSubmit(() => {
        onSelect(term);
      });
    }
  };

  return (
    <Combobox openOnFocus={true} onSelect={onSelect} aria-label={label}>
      <ComboboxTokenLabel onRemove={onRemove}>
        <ul
          aria-live="polite"
          aria-atomic={true}
          data-reach-combobox-token-list
        >
          {selections.map((selection) => (
            <ComboboxToken
              key={selection}
              value={optionLabelByValue(selection)}
            />
          ))}
        </ul>
        <ComboboxInput
          ref={inputRef}
          value={term}
          onChange={handleChange}
          onKeyDown={onKeyDown}
          onBlur={onBlur}
          autocomplete={false}
        />
      </ComboboxTokenLabel>
      {results && (results.length > 0 || !acceptNewValues) && (
        <ComboboxPopover className="shadow-popup">
          {results.length === 0 && (
            <p>
              Aucun résultat{' '}
              <button onClick={() => setTerm('')}>Effacer</button>
            </p>
          )}
          <ComboboxList>
            {results.map(([label, value], index) => {
              if (label.startsWith('--')) {
                return <ComboboxSeparator key={index} value={label} />;
              }
              return (
                <ComboboxOption
                  key={index}
                  value={label}
                  data-option-value={value}
                />
              );
            })}
          </ComboboxList>
        </ComboboxPopover>
      )}
    </Combobox>
  );
}

function ComboboxTokenLabel({ onRemove, ...props }) {
  const selectionsRef = useRef([]);

  useLayoutEffect(() => {
    selectionsRef.current = [];
    return () => (selectionsRef.current = []);
  });

  const context = {
    onRemove,
    selectionsRef
  };

  return (
    <Context.Provider value={context}>
      <div data-combobox-token-label {...props} />
    </Context.Provider>
  );
}

ComboboxTokenLabel.propTypes = {
  onRemove: PropTypes.func
};

function ComboboxSeparator({ value }) {
  return (
    <li aria-disabled="true" role="option" data-combobox-separator>
      {value.slice(2, -2)}
    </li>
  );
}

ComboboxSeparator.propTypes = {
  value: PropTypes.string
};

function ComboboxToken({ value, ...props }) {
  const { selectionsRef, onRemove } = useContext(Context);
  useEffect(() => {
    selectionsRef.current.push(value);
  });

  return (
    <li
      data-reach-combobox-token
      tabIndex="0"
      onKeyDown={(event) => {
        if (event.key === 'Backspace') {
          onRemove(value);
        }
      }}
      {...props}
    >
      <button
        type="button"
        tabIndex={-1}
        data-combobox-remove-token
        onClick={() => {
          onRemove(value);
        }}
      >
        <XIcon className="icon-size" />
        <span className="screen-reader-text">Désélectionner</span>
      </button>
      {value}
    </li>
  );
}

ComboboxToken.propTypes = {
  value: PropTypes.string,
  label: PropTypes.string
};

ComboMultipleDropdownList.propTypes = {
  options: PropTypes.oneOfType([
    PropTypes.arrayOf(PropTypes.string),
    PropTypes.arrayOf(
      PropTypes.arrayOf(
        PropTypes.oneOfType([PropTypes.string, PropTypes.number])
      )
    )
  ]),
  hiddenFieldId: PropTypes.string,
  selected: PropTypes.arrayOf(PropTypes.string),
  arraySelected: PropTypes.arrayOf(PropTypes.array),
  label: PropTypes.string,
  acceptNewValues: PropTypes.bool
};

export default ComboMultipleDropdownList;
