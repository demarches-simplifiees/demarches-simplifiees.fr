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
import { useId } from '@reach/auto-id';
import '@reach/combobox/styles.css';
import { matchSorter } from 'match-sorter';
import { XIcon } from '@heroicons/react/outline';
import isHotkey from 'is-hotkey';
import invariant from 'tiny-invariant';

import { useDeferredSubmit, useHiddenField } from './shared/hooks';

const Context = createContext();

function ComboMultiple({
  options,
  id,
  labelledby,
  describedby,
  label,
  group,
  name = 'value',
  selected,
  acceptNewValues = false
}) {
  invariant(id || label, 'ComboMultiple: `id` or a `label` are required');
  invariant(group, 'ComboMultiple: `group` is required');

  if (!Array.isArray(options[0])) {
    options = options.filter((o) => o).map((o) => [o, o]);
  }
  const inputRef = useRef();
  const [term, setTerm] = useState('');
  const [selections, setSelections] = useState(selected);
  const [newValues, setNewValues] = useState([]);
  const inputId = useId(id);
  const removedLabelledby = `${inputId}-remove`;
  const selectedLabelledby = `${inputId}-selected`;

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
  const [, setHiddenFieldValue, hiddenField] = useHiddenField(group, name);
  const awaitFormSubmit = useDeferredSubmit(hiddenField);

  const handleChange = (event) => {
    setTerm(event.target.value);
  };

  const saveSelection = (fn) => {
    setSelections((selections) => {
      selections = fn(selections);
      setHiddenFieldValue(JSON.stringify(selections));
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
    hidePopover();
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
    if (
      term &&
      [...extraOptions, ...options].map(([label]) => label).includes(term)
    ) {
      awaitFormSubmit(() => {
        onSelect(term);
      });
    } else {
      setTimeout(() => {
        hidePopover();
      }, 200);
    }
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
              describedby={removedLabelledby}
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
            {results.map(([label], index) => {
              if (label.startsWith('--')) {
                return <ComboboxSeparator key={index} value={label} />;
              }
              return <ComboboxOption key={index} value={label} />;
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
      <div data-reach-combobox-token-label {...props} />
    </Context.Provider>
  );
}

ComboboxTokenLabel.propTypes = {
  onRemove: PropTypes.func
};

function ComboboxSeparator({ value }) {
  return (
    <li aria-disabled="true" role="option" data-reach-combobox-separator>
      {value.slice(2, -2)}
    </li>
  );
}

ComboboxSeparator.propTypes = {
  value: PropTypes.string
};

function ComboboxToken({ value, describedby, ...props }) {
  const { selectionsRef, onRemove } = useContext(Context);
  useEffect(() => {
    selectionsRef.current.push(value);
  });

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
        {value}
      </button>
    </li>
  );
}

ComboboxToken.propTypes = {
  value: PropTypes.string,
  describedby: PropTypes.string
};

ComboMultiple.propTypes = {
  options: PropTypes.oneOfType([
    PropTypes.arrayOf(PropTypes.string),
    PropTypes.arrayOf(
      PropTypes.arrayOf(
        PropTypes.oneOfType([PropTypes.string, PropTypes.number])
      )
    )
  ]),
  selected: PropTypes.arrayOf(PropTypes.string),
  arraySelected: PropTypes.arrayOf(PropTypes.array),
  acceptNewValues: PropTypes.bool,
  mandatory: PropTypes.bool,
  id: PropTypes.string,
  group: PropTypes.string,
  name: PropTypes.string,
  labelledby: PropTypes.string,
  describedby: PropTypes.string,
  label: PropTypes.string
};

export default ComboMultiple;
