export function createTypeDeChampOperation(typeDeChamp, queue) {
  typeDeChamp = { ...typeDeChamp };
  delete typeDeChamp.types_de_champ;
  return queue
    .enqueue({
      path: '',
      method: 'post',
      payload: { type_de_champ: typeDeChamp }
    })
    .then((data) => {
      handleResponseData(typeDeChamp, data);
    });
}

export function destroyTypeDeChampOperation(typeDeChamp, queue) {
  return queue.enqueue({
    path: `/${typeDeChamp.id}`,
    method: 'delete',
    payload: {}
  });
}

export function moveTypeDeChampOperation(typeDeChamp, index, queue) {
  return queue.enqueue({
    path: `/${typeDeChamp.id}/move`,
    method: 'patch',
    payload: { position: index }
  });
}

export function updateTypeDeChampOperation(typeDeChamp, queue) {
  const path = `/${typeDeChamp.id}`;
  typeDeChamp = { ...typeDeChamp };
  delete typeDeChamp.id;
  delete typeDeChamp.private;
  delete typeDeChamp.types_de_champ;
  delete typeDeChamp.piece_justificative_template_filename;
  delete typeDeChamp.piece_justificative_template_url;
  return queue
    .enqueue({
      path,
      method: 'patch',
      payload: { type_de_champ: typeDeChamp }
    })
    .then((data) => {
      handleResponseData(typeDeChamp, data);
    });
}

function handleResponseData(typeDeChamp, { type_de_champ }) {
  for (let field of RESPONSE_FIELDS) {
    typeDeChamp[field] = type_de_champ[field];
  }
}

const RESPONSE_FIELDS = [
  'id',
  'piece_justificative_template_filename',
  'piece_justificative_template_url'
];
