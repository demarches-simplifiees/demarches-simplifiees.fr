import React, { Component } from 'react';
import PropTypes from 'prop-types';
import { library } from '@fortawesome/fontawesome-svg-core';
import {
  faArrowDown,
  faArrowsAltV,
  faArrowUp,
  faTrash
} from '@fortawesome/free-solid-svg-icons';

import Flash from './Flash';
import OperationsQueue from './OperationsQueue';
import TypeDeChamps from './components/TypeDeChamps';

library.add(faArrowDown, faArrowsAltV, faArrowUp, faTrash);

class TypesDeChampEditor extends Component {
  constructor({
    baseUrl,
    typeDeChampsTypes,
    directUploadUrl,
    isAnnotation,
    typeDeChamps
  }) {
    super({ typeDeChamps });
    const defaultTypeDeChampAttributes = {
      type_champ: 'text',
      types_de_champ: [],
      private: isAnnotation,
      libelle: `${isAnnotation ? 'Nouvelle annotation' : 'Nouveau champ'} ${
        typeDeChampsTypes[0][0]
      }`
    };
    this.state = {
      flash: new Flash(isAnnotation),
      queue: new OperationsQueue(baseUrl),
      defaultTypeDeChampAttributes,
      typeDeChampsTypes,
      directUploadUrl,
      isAnnotation
    };
  }

  render() {
    return (
      <TypeDeChamps state={this.state} typeDeChamps={this.props.typeDeChamps} />
    );
  }
}

TypesDeChampEditor.propTypes = {
  baseUrl: PropTypes.string,
  directUploadUrl: PropTypes.string,
  isAnnotation: PropTypes.bool,
  typeDeChamps: PropTypes.array,
  typeDeChampsTypes: PropTypes.array
};

export function createReactUJSElement(props) {
  return React.createElement(TypesDeChampEditor, props);
}

export default TypesDeChampEditor;
