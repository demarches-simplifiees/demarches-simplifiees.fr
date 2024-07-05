import { I18nProvider } from 'react-aria-components';
import { StrictMode, type ReactNode } from 'react';

export function Layout({ children }: { children: ReactNode }) {
  const locale = document.documentElement.lang;
  console.debug(`locale: ${locale}`);
  return (
    <I18nProvider locale={locale}>
      <StrictMode>{children}</StrictMode>
    </I18nProvider>
  );
}
