import React, { ChangeEvent } from 'react';

import Uploader from '../../../shared/activestorage/uploader';
import type { Handler } from '../types';

export function TypeDeChampPieceJustificative({
  isVisible,
  isTitreIdentite,
  url,
  filename,
  handler,
  directUploadUrl
}: {
  isVisible: boolean;
  isTitreIdentite: boolean;
  url?: string;
  filename?: string;
  handler: Handler<HTMLInputElement>;
  directUploadUrl: string;
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

  if (isTitreIdentite) {
    return (
      <div className="cell">
        <p id={`${handler.id}-description`}>
          Dans le cadre de la RGPD, le titre d&apos;identité sera supprimé lors
          de l&apos;acceptation du dossier
        </p>
      </div>
    );
  }
  return null;
}

function FileInformation({
  isVisible,
  url,
  filename
}: {
  isVisible: boolean;
  url?: string;
  filename?: string;
}) {
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

function onFileChange(
  handler: Handler<HTMLInputElement>,
  directUploadUrl: string
): (event: ChangeEvent<HTMLInputElement>) => void {
  return async ({ target }) => {
    const file = (target.files ?? [])[0];
    if (file) {
      const signedId = await uploadFile(target, file, directUploadUrl);
      handler.onChange({
        target: { value: signedId }
      } as ChangeEvent<HTMLInputElement>);
    }
  };
}

function uploadFile(
  input: HTMLInputElement,
  file: File,
  directUploadUrl: string
) {
  const controller = new Uploader(input, file, directUploadUrl);
  return controller.start().then((signedId) => {
    input.value = '';
    return signedId;
  });
}
