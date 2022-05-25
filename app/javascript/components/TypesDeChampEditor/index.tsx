import React from 'react';

import { Flash } from './Flash';
import { OperationsQueue } from './OperationsQueue';
import { TypeDeChamps } from './components/TypeDeChamps';
import { TypeDeChamp } from './types';

type TypesDeChampEditorProps = {
  baseUrl: string;
  continuerUrl: string;
  directUploadUrl: string;
  isAnnotation: boolean;
  typeDeChamps: TypeDeChamp[];
  typeDeChampsTypes: [label: string, type: string][];
  estimatedFillDuration: number;
};

export type State = Omit<TypesDeChampEditorProps, 'baseUrl'> & {
  flash: Flash;
  queue: OperationsQueue;
  defaultTypeDeChampAttributes: Pick<
    TypeDeChamp,
    | 'type_champ'
    | 'types_de_champ'
    | 'libelle'
    | 'private'
    | 'parent_id'
    | 'mandatory'
  >;
  prefix?: string;
  estimatedFillDuration?: number;
};

export default function TypesDeChampEditor(props: TypesDeChampEditorProps) {
  const defaultTypeDeChampAttributes: Omit<TypeDeChamp, 'id'> = {
    type_champ: 'text',
    types_de_champ: [],
    mandatory: false,
    private: props.isAnnotation,
    libelle: `${props.isAnnotation ? 'Nouvelle annotation' : 'Nouveau champ'} ${
      props.typeDeChampsTypes[0][0]
    }`
  };
  const state: State = {
    flash: new Flash(props.isAnnotation),
    queue: new OperationsQueue(props.baseUrl),
    defaultTypeDeChampAttributes,
    typeDeChamps: [],
    typeDeChampsTypes: props.typeDeChampsTypes,
    directUploadUrl: props.directUploadUrl,
    isAnnotation: props.isAnnotation,
    continuerUrl: props.continuerUrl,
    estimatedFillDuration: props.estimatedFillDuration
  };

  return <TypeDeChamps state={state} typeDeChamps={props.typeDeChamps} />;
}
