import ortho from './ortho.json';
import orthoCadastre from './orthoCadastre.json';
import vector from './vector.json';
import vectorCadastre from './vectorCadastre.json';

export function getMapStyle(style, hasCadastres) {
  if (hasCadastres) {
    return style === 'ortho' ? orthoCadastre : vectorCadastre;
  }
  return style === 'ortho' ? ortho : vector;
}
