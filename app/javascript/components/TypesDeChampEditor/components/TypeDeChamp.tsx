import React, { Dispatch } from 'react';
import { SortableElement, SortableHandle } from 'react-sortable-hoc';
import { useInView } from 'react-intersection-observer';
import { TrashIcon } from '@heroicons/react/outline';

import type { Action, TypeDeChamp, State, Handler } from '../types';
import { DescriptionInput } from './DescriptionInput';
import { LibelleInput } from './LibelleInput';
import { MandatoryInput } from './MandatoryInput';
import { MoveButton } from './MoveButton';
import { TypeDeChampCarteOption } from './TypeDeChampCarteOption';
import { TypeDeChampCarteOptions } from './TypeDeChampCarteOptions';
import { TypeDeChampTeFenuaOption } from './TypeDeChampTeFenuaOption';
import { TypeDeChampTeFenuaOptions } from './TypeDeChampTeFenuaOptions';
import { TypeDeChampIntegerOption } from './TypeDeChampIntegerOption';
import { TypeDeChampIntegerOptions } from './TypeDeChampIntegerOptions';
import { TypeDeChampLevelOption } from './TypeDeChampLevelOption';
import { TypeDeChampDateOption } from './TypeDeChampDateOption';
import { TypeDeChampDateOptions } from './TypeDeChampDateOptions';
import { TypeDeChampDropDownOptions } from './TypeDeChampDropDownOptions';
import { TypeDeChampDropDownOther } from './TypeDeChampDropDownOther';
import { TypeDeChampEmailList } from './TypeDeChampEmailList';
import { TypeDeChampHeaderSectionOptions } from './TypeDeChampHeaderSectionOptions';
import { TypeDeChampPieceJustificative } from './TypeDeChampPieceJustificative';
import { TypeDeChampRepetitionOptions } from './TypeDeChampRepetitionOptions';
import { TypeDeChampTypesSelect } from './TypeDeChampTypesSelect';
import { TypeDeChampDropDownSecondary } from './TypeDeChampDropDownSecondary';

type TypeDeChampProps = {
  typeDeChamp: TypeDeChamp;
  dispatch: Dispatch<Action>;
  idx: number;
  isFirstItem: boolean;
  isLastItem: boolean;
  state: State;
};

export const TypeDeChampComponent = SortableElement<TypeDeChampProps>(
  ({
    typeDeChamp,
    dispatch,
    idx: index,
    isFirstItem,
    isLastItem,
    state
  }: TypeDeChampProps) => {
    const isDropDown = [
      'drop_down_list',
      'multiple_drop_down_list',
      'linked_drop_down_list'
    ].includes(typeDeChamp.type_champ);
    const isLinkedDropDown = typeDeChamp.type_champ === 'linked_drop_down_list';
    const isSimpleDropDown = typeDeChamp.type_champ === 'drop_down_list';
    const isFile = typeDeChamp.type_champ === 'piece_justificative';
    const isCarte = typeDeChamp.type_champ === 'carte';
    const isTeFenua = typeDeChamp.type_champ === 'te_fenua';
    const isInteger = typeDeChamp.type_champ === 'integer_number';
    const isDate = typeDeChamp.type_champ === 'date';
    const isExplication = typeDeChamp.type_champ === 'explication';
    const isHeaderSection = typeDeChamp.type_champ === 'header_section';
    const isTitreIdentite = typeDeChamp.type_champ === 'titre_identite';
    const isRepetition = typeDeChamp.type_champ === 'repetition';
    const isVisa = typeDeChamp.type_champ === 'visa';
    const canBeMandatory =
      !isHeaderSection && !isExplication && !state.isAnnotation;

    const [ref, inView] = useInView({
      threshold: 0.6
    });

    const updateHandlers = createUpdateHandlers(
      dispatch,
      typeDeChamp,
      index,
      state.prefix
    );

    const typeDeChampsTypesForRepetition = state.typeDeChampsTypes.filter(
      ([, type]) => !EXCLUDE_FROM_REPETITION.includes(type)
    );

    return (
      <div
        ref={ref}
        data-index={index}
        data-in-view={inView ? true : undefined}
        data-repetition={isRepetition ? true : undefined}
        className={`type-de-champ form flex column justify-start ${
          isHeaderSection ? 'type-header-section' : ''
        }`}
      >
        <div
          className={`flex justify-start section head ${
            !isHeaderSection ? 'hr' : ''
          }`}
        >
          <DragHandle />
          <TypeDeChampTypesSelect
            handler={updateHandlers.type_champ}
            options={state.typeDeChampsTypes}
          />
          <div className="flex justify-start delete">
            <button
              className="button small icon-only danger"
              onClick={() => {
                if (confirm('Êtes vous sûr de vouloir supprimer ce champ ?'))
                  dispatch({
                    type: 'removeTypeDeChamp',
                    params: { typeDeChamp },
                    done: (estimatedFillDuration) => {
                      dispatch({
                        type: 'refresh',
                        params: { estimatedFillDuration }
                      });
                    }
                  });
              }}
            >
              <TrashIcon className="icon-size" />
              <span className="sr-only">Supprimer</span>
            </button>
          </div>
        </div>
        <div
          className={`flex justify-start section ${
            isDropDown ||
            isFile ||
            isCarte ||
            isTeFenua ||
            isInteger ||
            isDate ||
            isHeaderSection
              ? 'hr'
              : ''
          }`}
        >
          <div className="flex column justify-start">
            <MoveButton
              isEnabled={!isFirstItem}
              icon="arrow-up"
              title="Déplacer le champ vers le haut"
              onClick={() =>
                dispatch({
                  type: 'moveTypeDeChampUp',
                  params: { typeDeChamp }
                })
              }
            />
            <MoveButton
              isEnabled={!isLastItem}
              icon="arrow-down"
              title="Déplacer le champ vers le bas"
              onClick={() =>
                dispatch({
                  type: 'moveTypeDeChampDown',
                  params: { typeDeChamp }
                })
              }
            />
          </div>
          <div className="flex column justify-start">
            <LibelleInput handler={updateHandlers.libelle} isVisible={true} />
            <MandatoryInput
              handler={updateHandlers.mandatory}
              isVisible={canBeMandatory}
            />
          </div>
          <div className="flex justify-start">
            <DescriptionInput
              isVisible={!isHeaderSection && !isTitreIdentite}
              handler={updateHandlers.description}
            />
          </div>
        </div>
        <div className="flex justify-start section shift-left">
          <TypeDeChampDropDownOptions
            isVisible={isDropDown}
            handler={updateHandlers.drop_down_list_value}
          />
          <TypeDeChampDropDownSecondary
            isVisible={isLinkedDropDown}
            libelleHandler={updateHandlers.drop_down_secondary_libelle}
            descriptionHandler={updateHandlers.drop_down_secondary_description}
          />
          <TypeDeChampDropDownOther
            isVisible={isSimpleDropDown}
            handler={updateHandlers.drop_down_other}
          />
          <TypeDeChampPieceJustificative
            isVisible={isFile}
            isTitreIdentite={isTitreIdentite}
            directUploadUrl={state.directUploadUrl}
            filename={typeDeChamp.piece_justificative_template_filename}
            handler={updateHandlers.piece_justificative_template}
            url={typeDeChamp.piece_justificative_template_url}
          />
          <TypeDeChampCarteOptions isVisible={isCarte}>
            {Object.entries(OPTIONS_FIELDS).map(([field, label]) => (
              <TypeDeChampCarteOption
                key={field}
                label={label}
                handler={updateHandlers[field]}
              />
            ))}
          </TypeDeChampCarteOptions>
          <TypeDeChampTeFenuaOptions isVisible={isTeFenua}>
            <TypeDeChampTeFenuaOption
              label="Parcelles du cadastre"
              handler={updateHandlers.parcelles}
            />
            <TypeDeChampTeFenuaOption
              label="Batiments"
              handler={updateHandlers.batiments}
            />
            <TypeDeChampTeFenuaOption
              label="Zones manuelles"
              handler={updateHandlers.zones_manuelles}
            />
          </TypeDeChampTeFenuaOptions>
          <TypeDeChampIntegerOptions isVisible={isInteger}>
            <TypeDeChampIntegerOption
              label="Minimum"
              handler={updateHandlers.min}
            />
            <TypeDeChampIntegerOption
              label="Maximum"
              handler={updateHandlers.max}
            />
          </TypeDeChampIntegerOptions>
          <TypeDeChampHeaderSectionOptions isVisible={isHeaderSection}>
            <TypeDeChampLevelOption
              label="Niveau"
              handler={updateHandlers.level}
            />
          </TypeDeChampHeaderSectionOptions>
          <TypeDeChampDateOptions isVisible={isDate}>
            <TypeDeChampDateOption label="Début" handler={updateHandlers.min} />
            <TypeDeChampDateOption label="Fin" handler={updateHandlers.max} />
          </TypeDeChampDateOptions>
          <TypeDeChampEmailList
            isVisible={isVisa}
            handler={updateHandlers.accredited_user_string}
          />
          <TypeDeChampRepetitionOptions
            isVisible={isRepetition}
            state={{
              ...state,
              typeDeChampsTypes: typeDeChampsTypesForRepetition,
              prefix: `repetition-${index}`,
              typeDeChamps: typeDeChamp.types_de_champ || []
            }}
            typeDeChamp={typeDeChamp}
          />
        </div>
      </div>
    );
  }
);

const DragHandle = SortableHandle(() => (
  <div
    className="handle small icon-only icon move-handle"
    title="Déplacer le champ vers le haut ou vers le bas"
  />
));

type HandlerInputElement =
  | HTMLInputElement
  | HTMLTextAreaElement
  | HTMLSelectElement;

function createUpdateHandler(
  dispatch: Dispatch<Action>,
  typeDeChamp: TypeDeChamp,
  field: keyof TypeDeChamp,
  index: number,
  prefix?: string
): Handler<HandlerInputElement> {
  return {
    id: `${prefix ? `${prefix}-` : ''}champ-${index}-${field}`,
    name: field,
    value: getValue(typeDeChamp, field),
    onChange: ({ target }) =>
      dispatch({
        type: 'updateTypeDeChamp',
        params: {
          typeDeChamp,
          field,
          value: readValue(target)
        },
        done: (estimatedFillDuration: number) => {
          return dispatch({
            type: 'refresh',
            params: { estimatedFillDuration }
          });
        }
      })
  };
}

function createUpdateHandlers(
  dispatch: Dispatch<Action>,
  typeDeChamp: TypeDeChamp,
  index: number,
  prefix?: string
) {
  return FIELDS.reduce((handlers, field) => {
    handlers[field] = createUpdateHandler(
      dispatch,
      typeDeChamp,
      field as keyof TypeDeChamp,
      index,
      prefix
    );
    return handlers;
  }, {} as Record<string, Handler<HandlerInputElement>>);
}

const OPTIONS_FIELDS = {
  'options.cadastres': 'Cadastres',
  'options.unesco': 'UNESCO',
  'options.arretes_protection': 'Arrêtés de protection',
  'options.conservatoire_littoral': 'Conservatoire du Littoral',
  'options.reserves_chasse_faune_sauvage':
    'Réserves nationales de chasse et de faune sauvage',
  'options.reserves_biologiques': 'Réserves biologiques',
  'options.reserves_naturelles': 'Réserves naturelles',
  'options.natura_2000': 'Natura 2000',
  'options.zones_humides': 'Zones humides d’importance internationale',
  'options.znieff': 'ZNIEFF'
} as const;

export const FIELDS = [
  'batiments',
  'description',
  'drop_down_list_value',
  'drop_down_other',
  'level',
  'libelle',
  'mandatory',
  'parcelles',
  'parent_id',
  'piece_justificative_template',
  'private',
  'zones_manuelles',
  'min',
  'max',
  'accredited_user_string',
  'type_champ',
  'drop_down_secondary_libelle',
  'drop_down_secondary_description',
  ...Object.keys(OPTIONS_FIELDS)
] as const;

function getValue(obj: TypeDeChamp, path: string) {
  const [, optionsPath] = path.split('.');
  if (optionsPath) {
    return (obj.editable_options || {})[optionsPath];
  }
  return obj[path as keyof TypeDeChamp] as string;
}

function readValue(input: HandlerInputElement) {
  return input.type === 'checkbox' && 'checked' in input
    ? input.checked
    : input.value;
}

const EXCLUDE_FROM_REPETITION = [
  'carte',
  'dossier_link',
  'repetition',
  'siret',
  'visa'
];
