import React, {
  useState,
  useEffect,
  useRef,
  useId,
  ChangeEventHandler
} from 'react';
import { useDebounce } from 'use-debounce';
import { useQuery } from 'react-query';
import {
  Combobox,
  ComboboxInput,
  ComboboxPopover,
  ComboboxList,
  ComboboxOption
} from '@reach/combobox';
import '@reach/combobox/styles.css';
import invariant from 'tiny-invariant';

import { useDeferredSubmit, useHiddenField, groupId } from './shared/hooks';

type TransformResults<Result> = (term: string, results: unknown) => Result[];
type TransformResult<Result> = (
  result: Result
) => [key: string, value: string, label?: string];

export type ComboSearchProps<Result = unknown> = {
  onChange?: (value: string | null, result?: Result) => void;
  value?: string;
  scope: string;
  scopeExtra?: string;
  minimumInputLength: number;
  transformResults?: TransformResults<Result>;
  transformResult: TransformResult<Result>;
  allowInputValues?: boolean;
  id?: string;
  describedby?: string;
  className?: string;
  placeholder?: string;
  debounceDelay?: number;
  screenReaderInstructions: string;
  announceTemplateId: string;
};

type QueryKey = readonly [
  scope: string,
  term: string,
  extra: string | undefined
];

function ComboSearch<Result>({
  onChange,
  value: controlledValue,
  scope,
  scopeExtra,
  minimumInputLength,
  transformResult,
  allowInputValues = false,
  transformResults = (_, results) => results as Result[],
  id,
  describedby,
  screenReaderInstructions,
  announceTemplateId,
  debounceDelay = 0,
  ...props
}: ComboSearchProps<Result>) {
  invariant(id || onChange, 'ComboSearch: `id` or `onChange` are required');

  const group = !onChange && id ? groupId(id) : undefined;
  const [externalValue, setExternalValue, hiddenField] = useHiddenField(group);
  const [, setExternalId] = useHiddenField(group, 'external_id');
  const initialValue = externalValue ? externalValue : controlledValue;
  const [searchTerm, setSearchTerm] = useState('');
  const [debouncedSearchTerm] = useDebounce(searchTerm, debounceDelay);
  const [value, setValue] = useState(initialValue);
  const resultsMap = useRef<
    Record<string, { key: string; value: string; result: Result }>
  >({});
  const getLabel = (result: Result) => {
    const [, value, label] = transformResult(result);
    return label ?? value;
  };
  const setExternalValueAndId = (label: string) => {
    const { key, value, result } = resultsMap.current[label];
    if (onChange) {
      onChange(value, result);
    } else {
      setExternalId(key);
      setExternalValue(value);
    }
  };
  const awaitFormSubmit = useDeferredSubmit(hiddenField);

  const handleOnChange: ChangeEventHandler<HTMLInputElement> = ({
    target: { value }
  }) => {
    setValue(value);
    if (!value) {
      if (onChange) {
        onChange(null);
      } else {
        setExternalId('');
        setExternalValue('');
      }
    } else if (value.length >= minimumInputLength) {
      setSearchTerm(value.trim());
      if (allowInputValues) {
        setExternalId('');
        setExternalValue(value);
      }
    }
  };

  const handleOnSelect = (value: string) => {
    setExternalValueAndId(value);
    setValue(value);
    setSearchTerm('');
    awaitFormSubmit.done();
  };

  const { isSuccess, data } = useQuery<void, void, unknown, QueryKey>(
    [scope, debouncedSearchTerm, scopeExtra],
    {
      enabled: !!debouncedSearchTerm,
      refetchOnMount: false
    }
  );
  const results =
    isSuccess && data ? transformResults(debouncedSearchTerm, data) : [];

  const onBlur = () => {
    if (!allowInputValues && isSuccess && results[0]) {
      const label = getLabel(results[0]);
      awaitFormSubmit(() => {
        handleOnSelect(label);
      });
    }
  };

  const [announceLive, setAnnounceLive] = useState('');
  const announceTimeout = useRef<ReturnType<typeof setTimeout>>();
  const announceTemplate = document.querySelector<HTMLTemplateElement>(
    `#${announceTemplateId}`
  );
  invariant(announceTemplate, `Missing #${announceTemplateId}`);

  const announceFragment = useRef(
    announceTemplate.content.cloneNode(true) as DocumentFragment
  ).current;

  useEffect(() => {
    if (isSuccess) {
      const slot = announceFragment.querySelector<HTMLSlotElement>(
        'slot[name="' + (results.length <= 1 ? results.length : 'many') + '"]'
      );

      if (!slot) {
        return;
      }

      const countSlot =
        slot.querySelector<HTMLSlotElement>('slot[name="count"]');
      if (countSlot) {
        countSlot.replaceWith(String(results.length));
      }

      setAnnounceLive(slot.textContent ?? '');
    }

    announceTimeout.current = setTimeout(() => {
      setAnnounceLive('');
    }, 3000);

    return () => clearTimeout(announceTimeout.current);
  }, [announceFragment, results.length, isSuccess]);

  const initInstrId = useId();
  const resultsId = useId();

  return (
    <Combobox onSelect={handleOnSelect}>
      <ComboboxInput
        {...props}
        onChange={handleOnChange}
        onBlur={onBlur}
        value={value ?? ''}
        autocomplete={false}
        id={id}
        aria-describedby={describedby ?? initInstrId}
        aria-owns={resultsId}
      />
      {isSuccess && (
        <ComboboxPopover id={resultsId} className="shadow-popup">
          {results.length > 0 ? (
            <ComboboxList>
              {results.map((result, index) => {
                const label = getLabel(result);
                const [key, value] = transformResult(result);
                resultsMap.current[label] = { key, value, result };
                return <ComboboxOption key={`${key}-${index}`} value={label} />;
              })}
            </ComboboxList>
          ) : (
            <span style={{ display: 'block', margin: 8 }}>
              Aucun résultat trouvé
            </span>
          )}
        </ComboboxPopover>
      )}
      {!describedby && (
        <span id={initInstrId} className="hidden">
          {screenReaderInstructions}
        </span>
      )}
      <div aria-live="assertive" className="sr-only">
        {announceLive}
      </div>
    </Combobox>
  );
}

export default ComboSearch;
