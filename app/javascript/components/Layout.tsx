import { I18nProvider } from 'react-aria-components';
import { UNSAFE_PortalProvider } from 'react-aria';
import { StrictMode, type ReactNode } from 'react';
import { findOrCreateContainerElement } from '@coldwired/react';

const getContainer = () =>
  findOrCreateContainerElement('rac-portal') as HTMLElement;

export function Layout({ children }: { children: ReactNode }) {
  const locale = document.documentElement.lang;
  console.debug(`locale: ${locale}`);
  return (
    <I18nProvider locale={locale}>
      <UNSAFE_PortalProvider getContainer={getContainer}>
        <StrictMode>{children}</StrictMode>
      </UNSAFE_PortalProvider>
    </I18nProvider>
  );
}
