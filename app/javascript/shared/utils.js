export function show({ classList }) {
  classList.remove('hidden');
}

export function hide({ classList }) {
  classList.add('hidden');
}

export function toggle({ classList }) {
  classList.toggle('hidden');
}
