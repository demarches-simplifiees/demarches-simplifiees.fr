import React, { Component } from 'react';
import PropTypes from 'prop-types';

import Flash from './Flash';
import OperationsQueue from './OperationsQueue';
import TypeDeChamps from './components/TypeDeChamps';

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
      isAnnotation: props.isAnnotation,
      continuerUrl: props.continuerUrl
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
  continuerUrl: PropTypes.string,
  directUploadUrl: PropTypes.string,
  isAnnotation: PropTypes.bool,
  typeDeChamps: PropTypes.array,
  typeDeChampsTypes: PropTypes.array
};

export default TypesDeChampEditor;
