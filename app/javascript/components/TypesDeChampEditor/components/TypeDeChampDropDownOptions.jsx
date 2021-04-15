import React from 'react';
import PropTypes from 'prop-types';

function TypeDeChampDropDownOptions({ isVisible, handler }) {
  if (isVisible) {
    return (
      <div className="cell">
        <label className="cell" htmlFor={handler.id}>
          Liste déroulante
        </label>
        <div className="flex justify-start">
          <div className="cell">
            <textarea
              id={handler.id}
              name={handler.name}
              value={handler.value}
              onChange={handler.onChange}
              rows={3}
              cols={40}
              placeholder="Ecrire une valeur par ligne"
              className="small-margin small"
            />
          </div>
          <div className="cell">
            <p>
              Ecrire une valeur par ligne.
              <br />
              Entrer &lsquo;-- catégorie --&rsquo; pour une catégorie, un
              séparateur. <br />
              Pour les listes déroulantes simples, commencer la liste par
              &lsquo;Autre&rsquo; si l&apos;utilisateur peut entrer une valeur
              autre que celles listées.
              <br />
              Pour les doubles menus déroulants liés, entourez les valeurs de
              1er niveau par &lsquo;--&rsquo; (&lsquo;--Valeur 1er
              Niveau--&rsquo;) puis lister les valeurs de second niveau.
            </p>
          </div>
        </div>
      </div>
    );
  }
  return null;
}

TypeDeChampDropDownOptions.propTypes = {
  isVisible: PropTypes.bool,
  value: PropTypes.string,
  handler: PropTypes.object
};

export default TypeDeChampDropDownOptions;
