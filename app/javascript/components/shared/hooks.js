import { useRef, useCallback, useMemo, useState } from 'react';
import { fire } from '@utils';

export function useDeferredSubmit(input) {
  const calledRef = useRef(false);
  const awaitFormSubmit = useCallback(
    (callback) => {
      const form = input?.form;
      if (!form) {
        return;
      }
      const interceptFormSubmit = (event) => {
        event.preventDefault();
        runCallback();
        form.submit();
      };
      calledRef.current = false;
      form.addEventListener('submit', interceptFormSubmit);
      const runCallback = () => {
        form.removeEventListener('submit', interceptFormSubmit);
        clearTimeout(timer);
        if (!calledRef.current) {
          callback();
        }
      };
      const timer = setTimeout(runCallback, 400);
    },
    [input]
  );
  awaitFormSubmit.done = () => {
    calledRef.current = true;
  };
  return awaitFormSubmit;
}

export function groupId(id) {
  return `#champ-${id.replace(/-input$/, '')}`;
}

export function useHiddenField(group, name = 'value') {
  const hiddenField = useMemo(
    () => selectInputInGroup(group, name),
    [group, name]
  );
  const [value, setValue] = useState(() => hiddenField?.value);

  return [
    value,
    (value) => {
      if (hiddenField) {
        hiddenField.setAttribute('value', value);
        setValue(value);
        fire(hiddenField, 'autosave:trigger');
      }
    },
    hiddenField
  ];
}

function selectInputInGroup(group, name) {
  if (group) {
    return document.querySelector(
      `${group} input[type="hidden"][name$="[${name}]"], ${group} input[type="hidden"][name="${name}"]`
    );
  }
}
