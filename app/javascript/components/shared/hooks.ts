import { useRef, useCallback, useMemo, useState } from 'react';
import { fire } from '@utils';

export function useDeferredSubmit(input?: HTMLInputElement): {
  (callback: () => void): void;
  done: () => void;
} {
  const calledRef = useRef(false);
  const awaitFormSubmit = useCallback(
    (callback: () => void) => {
      const form = input?.form;
      if (!form) {
        return;
      }
      const interceptFormSubmit = (event: Event) => {
        event.preventDefault();
        runCallback();

        if (
          !Array.from(form.elements).some(
            (e) =>
              e.hasAttribute('data-direct-upload-url') &&
              'value' in e &&
              e.value != ''
          )
        ) {
          form.submit();
        }
        // else: form will be submitted by diret upload once file have been uploaded
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
  const done = () => {
    calledRef.current = true;
  };
  return Object.assign(awaitFormSubmit, { done });
}

export function groupId(id: string) {
  return `#${id.replace(/-input$/, '')}`;
}

export function useHiddenField(
  group?: string,
  name = 'value'
): [
  value: string | undefined,
  setValue: (value: string) => void,
  input: HTMLInputElement | undefined
] {
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
        fire(hiddenField, 'change');
      }
    },
    hiddenField ?? undefined
  ];
}

function selectInputInGroup(
  group: string | undefined,
  name: string
): HTMLInputElement | undefined | null {
  if (group) {
    return document.querySelector<HTMLInputElement>(
      `${group} input[type="hidden"][name$="[${name}]"], ${group} input[type="hidden"][name="${name}"]`
    );
  }
}
