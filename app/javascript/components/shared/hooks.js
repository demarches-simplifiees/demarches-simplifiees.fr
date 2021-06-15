import { useRef, useCallback } from 'react';

export function useDeferredSubmit(input) {
  const calledRef = useRef(false);
  const awaitFormSubmit = useCallback(
    (callback) => {
      const form = input.form;
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
