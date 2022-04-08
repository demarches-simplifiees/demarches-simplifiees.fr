import type { ChangeEventHandler } from 'react';

export type { Flash } from './Flash';
export type { OperationsQueue } from './OperationsQueue';
export type { State } from '.';
export { Action } from './typeDeChampsReducer';

export type TypeDeChamp = {
  id: string;
  libelle: string;
  type_champ: string;
  private: boolean;
  mandatory: boolean;
  types_de_champ: TypeDeChamp[];
  parent_id?: string;
  piece_justificative_template_filename?: string;
  piece_justificative_template_url?: string;
  drop_down_list_value?: string;
  editable_options?: Record<string, string>;
};

export type Handler<Element extends HTMLElement> = {
  id: string;
  name: string;
  value: string;
  onChange: ChangeEventHandler<Element>;
};
