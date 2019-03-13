import ReactDOM from 'react-dom';

// This attribute holds the name of component which should be mounted
// example: `data-react-class="MyApp.Items.EditForm"`
const CLASS_NAME_ATTR = 'data-react-class';

// This attribute holds JSON stringified props for initializing the component
// example: `data-react-props="{\"item\": { \"id\": 1, \"name\": \"My Item\"} }"`
const PROPS_ATTR = 'data-react-props';

// This attribute holds which method to use between: ReactDOM.hydrate, ReactDOM.render
const RENDER_ATTR = 'data-hydrate';

function findDOMNodes() {
  return document.querySelectorAll(`[${CLASS_NAME_ATTR}]`);
}

export default class ReactUJS {
  constructor(loadComponent) {
    this.loadComponent = loadComponent;
  }

  async mountComponents() {
    const nodes = findDOMNodes();

    for (let node of nodes) {
      const className = node.getAttribute(CLASS_NAME_ATTR);
      const createReactUJSElement = await this.loadComponent(className).catch(
        () => null
      );

      if (!createReactUJSElement) {
        const message = "Cannot find component: '" + className + "'";
        // eslint-disable-next-line no-console
        console.error(
          '%c[react-rails] %c' + message + ' for element',
          'font-weight: bold',
          '',
          node
        );
        throw new Error(
          message + '. Make sure your component is available to render.'
        );
      } else {
        const propsJson = node.getAttribute(PROPS_ATTR);
        const props = propsJson && JSON.parse(propsJson);
        const hydrate = node.getAttribute(RENDER_ATTR);

        if (hydrate && typeof ReactDOM.hydrate === 'function') {
          ReactDOM.hydrate(createReactUJSElement(props), node);
        } else {
          ReactDOM.render(createReactUJSElement(props), node);
        }
      }
    }
  }

  start() {
    addEventListener('turbolinks:load', () => this.mountComponents());
  }
}
