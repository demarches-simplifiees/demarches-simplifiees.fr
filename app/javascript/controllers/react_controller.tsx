import { Controller } from '@hotwired/stimulus';
import React from 'react';
import { render, unmountComponentAtNode } from 'react-dom';
import invariant from 'tiny-invariant';

type Props = Record<string, unknown>;

const componentsRegistry = new Map();

import ComboAdresseSearch from '../components/ComboAdresseSearch';
import ComboAnnuaireEducationSearch from '../components/ComboAnnuaireEducationSearch';
import ComboCommunesSearch from '../components/ComboCommunesSearch';
import ComboDepartementsSearch from '../components/ComboDepartementsSearch';
import ComboMultiple from '../components/ComboMultiple';
import ComboMultipleDropdownList from '../components/ComboMultipleDropdownList';
import ComboPaysSearch from '../components/ComboPaysSearch';
import ComboRegionsSearch from '../components/ComboRegionsSearch';
import ComboSearch from '../components/ComboSearch';
import MapEditor from '../components/MapEditor';
import MapReader from '../components/MapReader';

componentsRegistry.set('ComboAdresseSearch', ComboAdresseSearch);
componentsRegistry.set(
  'ComboAnnuaireEducationSearch',
  ComboAnnuaireEducationSearch
);
componentsRegistry.set('ComboCommunesSearch', ComboCommunesSearch);
componentsRegistry.set('ComboDepartementsSearch', ComboDepartementsSearch);
componentsRegistry.set('ComboMultiple', ComboMultiple);
componentsRegistry.set('ComboMultipleDropdownList', ComboMultipleDropdownList);
componentsRegistry.set('ComboPaysSearch', ComboPaysSearch);
componentsRegistry.set('ComboRegionsSearch', ComboRegionsSearch);
componentsRegistry.set('ComboSearch', ComboSearch);
componentsRegistry.set('MapEditor', MapEditor);
componentsRegistry.set('MapReader', MapReader);

// Initialize React components when their markup appears into the DOM.
//
// Example:
//   <div data-controller="react" data-react-component-value="ComboMultiple" data-react-props-value="{}"></div>
//
export class ReactController extends Controller {
  static values = {
    component: String,
    props: Object
  };

  declare readonly componentValue: string;
  declare readonly propsValue: Props;

  connect(): void {
    this.mountComponent(this.element as HTMLElement);
  }

  disconnect(): void {
    unmountComponentAtNode(this.element as HTMLElement);
  }

  private mountComponent(node: HTMLElement): void {
    const componentName = this.componentValue;
    const props = this.propsValue;
    const Component = this.getComponent(componentName);

    invariant(
      Component,
      `Cannot find a React component with class "${componentName}"`
    );
    render(<Component {...props} />, node);
  }

  private getComponent(componentName: string) {
    return componentsRegistry.get(componentName) ?? null;
  }
}
