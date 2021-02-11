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
import matchSorter from 'match-sorter';
import { fire } from '@utils';

const Context = createContext();

function ComboMultipleDropdownList({
  options,
  hiddenFieldId,
  selected,
  label
}) {
  if (label == undefined) {
    label = 'Choisir une option';
  }
  if (Array.isArray(options[0]) == false) {
    options = options.map((o) => [o, o]);
  }
  const inputRef = useRef();
  const [term, setTerm] = useState('');
  const [selections, setSelections] = useState(selected);
  const results = useMemo(
    () =>
      (term
        ? matchSorter(
            options.filter((o) => !o[0].startsWith('--')),
            term
          )
        : options
      ).filter((o) => o[0] && !selections.includes(o[1])),
    [term, selections]
  );
  const hiddenField = useMemo(
    () => document.querySelector(`input[data-uuid="${hiddenFieldId}"]`),
    [hiddenFieldId]
  );

  const handleChange = (event) => {
    setTerm(event.target.value);
  };

  const saveSelection = (selections) => {
    setSelections(selections);
    if (hiddenField) {
      hiddenField.setAttribute('value', JSON.stringify(selections));
      fire(hiddenField, 'autosave:trigger');
    }
  };

  const onSelect = (value) => {
    let sel = options.find((o) => o[0] == value)[1];
    saveSelection([...selections, sel]);
    setTerm('');
  };

  const onRemove = (value) => {
    saveSelection(
      selections.filter((s) => s !== options.find((o) => o[0] == value)[1])
    );
    inputRef.current.focus();
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
              value={options.find((o) => o[1] == selection)[0]}
            />
          ))}
        </ul>
        <ComboboxInput
          ref={inputRef}
          value={term}
          onChange={handleChange}
          autocomplete={false}
        />
      </ComboboxTokenLabel>
      {results && (
        <ComboboxPopover portal={false}>
          {results.length === 0 && (
            <p>
              Aucun résultat{' '}
              <button
                onClick={() => {
                  setTerm('');
                }}
              >
                Effacer
              </button>
            </p>
          )}
          <ComboboxList>
            {results.map((value, index) => {
              if (value[0].startsWith('--')) {
                return <ComboboxSeparator key={index} value={value[0]} />;
              }
              return <ComboboxOption key={index} value={value[0]} />;
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
      <span
        role="presentation"
        data-combobox-remove-token
        onClick={() => {
          onRemove(value);
        }}
      >
        x
      </span>
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
  label: PropTypes.string
};

export default ComboMultipleDropdownList;
