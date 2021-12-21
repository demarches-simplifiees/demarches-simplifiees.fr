import React, { Suspense, lazy, createElement } from 'react';
import { render } from 'react-dom';

// This attribute holds the name of component which should be mounted
// example: `data-react-class="MyApp.Items.EditForm"`
const CLASS_NAME_ATTR = 'data-react-class';

// This attribute holds JSON stringified props for initializing the component
// example: `data-react-props="{\"item\": { \"id\": 1, \"name\": \"My Item\"} }"`
const PROPS_ATTR = 'data-react-props';

// A unique identifier to identify a node
const CACHE_ID_ATTR = 'data-react-cache-id';

const CLASS_NAME_SELECTOR = `[${CLASS_NAME_ATTR}]`;

// helper method for the mount and unmount methods to find the
// `data-react-class` DOM elements
function findDOMNodes(searchSelector) {
  const [selector, parent] = getSelector(searchSelector);
  return parent.querySelectorAll(selector);
}

function getSelector(searchSelector) {
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
  #cache = {};
  #components;

  constructor(components) {
    this.#components = components;
  }

  getConstructor(className) {
    return this.#components[className];
  }

  mountComponents(searchSelector) {
    const nodes = findDOMNodes(searchSelector);

    for (const node of nodes) {
      const className = node.getAttribute(CLASS_NAME_ATTR);
      const ComponentClass = this.getConstructor(className);
      const propsJson = node.getAttribute(PROPS_ATTR);
      const props = propsJson && JSON.parse(propsJson);
      const cacheId = node.getAttribute(CACHE_ID_ATTR);

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
        let component = this.#cache[cacheId];
        if (!component) {
          this.#cache[cacheId] = component = createElement(
            ComponentClass,
            props
          );
        }

        render(component, node);
      }
    }
  }
}

const Loader = () => <div className="spinner left" />;

export function Loadable(loader) {
  const LazyComponent = lazy(loader);

  return function PureComponent(props) {
    return (
      <Suspense fallback={<Loader />}>
        <LazyComponent {...props} />
      </Suspense>
    );
  };
}

export function registerReactComponents(components) {
  const registry = new ReactComponentRegistry(components);

  addEventListener('ds:page:update', () => registry.mountComponents());
}
