import React, { Component } from 'react';
import PropTypes from 'prop-types';
import { library } from '@fortawesome/fontawesome-svg-core';

import { faArrowCircleDown } from '@fortawesome/free-solid-svg-icons/faArrowCircleDown';
import { faArrowDown } from '@fortawesome/free-solid-svg-icons/faArrowDown';
import { faArrowsAltV } from '@fortawesome/free-solid-svg-icons/faArrowsAltV';
import { faArrowUp } from '@fortawesome/free-solid-svg-icons/faArrowUp';
import { faPlus } from '@fortawesome/free-solid-svg-icons/faPlus';
import { faTrash } from '@fortawesome/free-solid-svg-icons/faTrash';

import Flash from './Flash';
import OperationsQueue from './OperationsQueue';
import TypeDeChamps from './components/TypeDeChamps';

library.add(
  faArrowCircleDown,
  faArrowDown,
  faArrowsAltV,
  faArrowUp,
  faPlus,
  faTrash
);

class TypesDeChampEditor extends Component {
  constructor(props) {
    super(props);
    const defaultTypeDeChampAttributes = {
      type_champ: 'text',
      types_de_champ: [],
      private: props.isAnnotation,
      libelle: `${
        props.isAnnotation ? 'Nouvelle annotation' : 'Nouveau champ'
      } ${props.typeDeChampsTypes[0][0]}`
    };
    this.state = {
      flash: new Flash(props.isAnnotation),
      queue: new OperationsQueue(props.baseUrl),
      defaultTypeDeChampAttributes,
      typeDeChampsTypes: props.typeDeChampsTypes,
      directUploadUrl: props.directUploadUrl,
      isAnnotation: props.isAnnotation
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

export default TypesDeChampEditor;
