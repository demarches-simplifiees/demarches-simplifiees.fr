import React, { Suspense, lazy, createElement, ComponentClass } from 'react';
import { render } from 'react-dom';

// This attribute holds the name of component which should be mounted
// example: `data-react-class="MyApp.Items.EditForm"`
const CLASS_NAME_ATTR = 'data-react-class';

// This attribute holds JSON stringified props for initializing the component
// example: `data-react-props="{\"item\": { \"id\": 1, \"name\": \"My Item\"} }"`
const PROPS_ATTR = 'data-react-props';

const CLASS_NAME_SELECTOR = `[${CLASS_NAME_ATTR}]`;

// helper method for the mount and unmount methods to find the
// `data-react-class` DOM elements
function findDOMNodes(searchSelector?: string): NodeListOf<HTMLDivElement> {
  const [selector, parent] = getSelector(searchSelector);
  return parent.querySelectorAll<HTMLDivElement>(selector);
}

function getSelector(searchSelector?: string): [string, Document] {
  switch (typeof searchSelector) {
    case 'undefined':
      return [CLASS_NAME_SELECTOR, document];
    case 'object':
      return [CLASS_NAME_SELECTOR, searchSelector];
    case 'string':
      return [
        ['', ' ']
          .map(
            (separator) => `${searchSelector}${separator}${CLASS_NAME_SELECTOR}`
          )
          .join(', '),
        document
      ];
  }
}

class ReactComponentRegistry {
  #components;

  constructor(components: Record<string, ComponentClass>) {
    this.#components = components;
  }

  getConstructor(className: string | null) {
    return className ? this.#components[className] : null;
  }

  mountComponents(searchSelector?: string) {
    const nodes = findDOMNodes(searchSelector);

    for (const node of nodes) {
      const className = node.getAttribute(CLASS_NAME_ATTR);
      const ComponentClass = this.getConstructor(className);
      const propsJson = node.getAttribute(PROPS_ATTR);
      const props = propsJson && JSON.parse(propsJson);

      if (!ComponentClass) {
        const message = `Cannot find component: "${className}"`;
        console?.log(
          `%c[react-rails] %c${message} for element`,
          'font-weight: bold',
          '',
          node
        );
        throw new Error(
          `${message}. Make sure your component is available to render.`
        );
      } else {
        render(createElement(ComponentClass, props), node);
      }
    }
  }
}

const Loader = () => <div className="spinner left" />;

export function Loadable(loader: () => Promise<{ default: ComponentClass }>) {
  const LazyComponent = lazy(loader);

  return function PureComponent(props: Record<string, unknown>) {
    return (
      <Suspense fallback={<Loader />}>
        <LazyComponent {...props} />
      </Suspense>
    );
  };
}

export function registerReactComponents(
  components: Record<string, ComponentClass>
) {
  const registry = new ReactComponentRegistry(components);

  addEventListener('ds:page:update', () => registry.mountComponents());
}
