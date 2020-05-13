import React from 'react';
import PropTypes from 'prop-types';
import Uploader from '../../../shared/activestorage/uploader';

function TypeDeChampPieceJustificative({
  isVisible,
  url,
  filename,
  handler,
  directUploadUrl
}) {
  if (isVisible) {
    const hasFile = !!filename;
    return (
      <div className="cell">
        <label htmlFor={handler.id}>Modèle</label>
        <FileInformation isVisible={hasFile} url={url} filename={filename} />
        <input
          type="file"
          id={handler.id}
          name={handler.name}
          onChange={onFileChange(handler, directUploadUrl)}
          className="small-margin small"
        />
      </div>
    );
  }
  return null;
}

TypeDeChampPieceJustificative.propTypes = {
  isVisible: PropTypes.bool,
  url: PropTypes.string,
  filename: PropTypes.string,
  handler: PropTypes.object,
  directUploadUrl: PropTypes.string
};

function FileInformation({ isVisible, url, filename }) {
  if (isVisible) {
    return (
      <>
        <a href={url} rel="noopener noreferrer" target="_blank">
          {filename}
        </a>
        <br /> Modifier :
      </>
    );
  }
  return null;
}

FileInformation.propTypes = {
  isVisible: PropTypes.bool,
  url: PropTypes.string,
  filename: PropTypes.string
};

function onFileChange(handler, directUploadUrl) {
  return async ({ target }) => {
    const file = target.files[0];
    if (file) {
      const signedId = await uploadFile(target, file, directUploadUrl);
      handler.onChange({
        target: {
          value: signedId
        }
      });
    }
  };
}

function uploadFile(input, file, directUploadUrl) {
  const controller = new Uploader(input, file, directUploadUrl);
  return controller.start().then((signedId) => {
    input.value = null;
    return signedId;
  });
}

export default TypeDeChampPieceJustificative;
