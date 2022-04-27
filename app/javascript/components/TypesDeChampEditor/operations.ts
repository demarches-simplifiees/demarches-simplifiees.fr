import type { TypeDeChamp, OperationsQueue } from './types';

export function createTypeDeChampOperation(
  typeDeChamp: Omit<TypeDeChamp, 'id'>,
  queue: OperationsQueue
) {
  return queue
    .enqueue({
      path: '',
      method: 'post',
      payload: { type_de_champ: typeDeChamp }
    })
    .then((data) => {
      handleResponseData(typeDeChamp, data as ResponseData);
    });
}

export function destroyTypeDeChampOperation(
  typeDeChamp: TypeDeChamp,
  queue: OperationsQueue
) {
  return queue.enqueue({
    path: `/${typeDeChamp.id}`,
    method: 'delete',
    payload: {}
  });
}

export function moveTypeDeChampOperation(
  typeDeChamp: TypeDeChamp,
  index: number,
  queue: OperationsQueue
) {
  return queue.enqueue({
    path: `/${typeDeChamp.id}/move`,
    method: 'patch',
    payload: { position: index }
  });
}

export function updateTypeDeChampOperation(
  typeDeChamp: TypeDeChamp,
  queue: OperationsQueue
) {
  return queue
    .enqueue({
      path: `/${typeDeChamp.id}`,
      method: 'patch',
      payload: { type_de_champ: typeDeChamp }
    })
    .then((data) => {
      handleResponseData(typeDeChamp, data as ResponseData);
    });
}

type ResponseData = { type_de_champ: Record<string, string> };

function handleResponseData(
  typeDeChamp: Partial<TypeDeChamp>,
  { type_de_champ }: ResponseData
) {
  for (const field of RESPONSE_FIELDS) {
    typeDeChamp[field] = type_de_champ[field];
  }
}

const RESPONSE_FIELDS = [
  'id',
  'piece_justificative_template_filename',
  'piece_justificative_template_url'
] as const;
