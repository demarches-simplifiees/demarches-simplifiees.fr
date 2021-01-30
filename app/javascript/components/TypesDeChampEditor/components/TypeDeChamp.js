import React from 'react';
import PropTypes from 'prop-types';
import { sortableElement, sortableHandle } from 'react-sortable-hoc';
import { useInView } from 'react-intersection-observer';
import { FontAwesomeIcon } from '@fortawesome/react-fontawesome';

import DescriptionInput from './DescriptionInput';
import LibelleInput from './LibelleInput';
import MandatoryInput from './MandatoryInput';
import MoveButton from './MoveButton';
import TypeDeChampCarteOption from './TypeDeChampCarteOption';
import TypeDeChampCarteOptions from './TypeDeChampCarteOptions';
import TypeDeChampTeFenuaOption from './TypeDeChampTeFenuaOption';
import TypeDeChampTeFenuaOptions from './TypeDeChampTeFenuaOptions';
import TypeDeChampIntegerOption from './TypeDeChampIntegerOption';
import TypeDeChampIntegerOptions from './TypeDeChampIntegerOptions';
import TypeDeChampLevelOption from './TypeDeChampLevelOption';
import TypeDeChampDateOption from './TypeDeChampDateOption';
import TypeDeChampDateOptions from './TypeDeChampDateOptions';
import TypeDeChampDropDownOptions from './TypeDeChampDropDownOptions';
import TypeDeChampPieceJustificative from './TypeDeChampPieceJustificative';
import TypeDeChampRepetitionOptions from './TypeDeChampRepetitionOptions';
import TypeDeChampTypesSelect from './TypeDeChampTypesSelect';
import TypeDeChampHeaderSectionOptions from './TypeDeChampHeaderSectionOptions';

const TypeDeChamp = sortableElement(
  ({ typeDeChamp, dispatch, idx: index, isFirstItem, isLastItem, state }) => {
    const isDropDown = [
      'auto_completion',
      'drop_down_list',
      'multiple_drop_down_list',
      'linked_drop_down_list'
    ].includes(typeDeChamp.type_champ);
    const isFile = typeDeChamp.type_champ === 'piece_justificative';
    const isCarte = typeDeChamp.type_champ === 'carte';
    const isTeFenua = typeDeChamp.type_champ === 'te_fenua';
    const isInteger = typeDeChamp.type_champ === 'integer_number';
    const isDate = typeDeChamp.type_champ === 'date';
    const isExplication = typeDeChamp.type_champ === 'explication';
    const isHeaderSection = typeDeChamp.type_champ === 'header_section';
    const isTitreIdentite = typeDeChamp.type_champ === 'titre_identite';
    const isRepetition = typeDeChamp.type_champ === 'repetition';
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
                    params: { typeDeChamp }
                  });
              }}
            >
              <FontAwesomeIcon icon="trash" title="Supprimer" />
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
          <TypeDeChampPieceJustificative
            isVisible={isFile}
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
            <TypeDeChampLevelOption
              label="Niveau2"
              handler={updateHandlers.level}
            />
          </TypeDeChampHeaderSectionOptions>
          <TypeDeChampDateOptions isVisible={isDate}>
            <TypeDeChampDateOption label="Début" handler={updateHandlers.min} />
            <TypeDeChampDateOption label="Fin" handler={updateHandlers.max} />
          </TypeDeChampDateOptions>
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

TypeDeChamp.propTypes = {
  dispatch: PropTypes.func,
  idx: PropTypes.number,
  isFirstItem: PropTypes.bool,
  isLastItem: PropTypes.bool,
  state: PropTypes.object,
  typeDeChamp: PropTypes.object
};

const DragHandle = sortableHandle(() => (
  <div
    className="handle small icon-only icon move-handle"
    title="Déplacer le champ vers le haut ou vers le bas"
  />
));

function createUpdateHandler(dispatch, typeDeChamp, field, index, prefix) {
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
        done: () => dispatch({ type: 'refresh' })
      })
  };
}

function getValue(obj, path) {
  const [, optionsPath] = path.split('.');
  if (optionsPath) {
    return (obj.editable_options || {})[optionsPath];
  }
  return obj[path];
}

function createUpdateHandlers(dispatch, typeDeChamp, index, prefix) {
  return FIELDS.reduce((handlers, field) => {
    handlers[field] = createUpdateHandler(
      dispatch,
      typeDeChamp,
      field,
      index,
      prefix
    );
    return handlers;
  }, {});
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
};

export const FIELDS = [
  'batiments',
  'description',
  'drop_down_list_value',
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
  'type_champ',
  ...Object.keys(OPTIONS_FIELDS)
];

function readValue(input) {
  return input.type === 'checkbox' ? input.checked : input.value;
}

const EXCLUDE_FROM_REPETITION = [
  'carte',
  'dossier_link',
  'repetition',
  'siret'
];

export default TypeDeChamp;
