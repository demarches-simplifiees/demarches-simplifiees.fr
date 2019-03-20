export default function reactComponents(className) {
  switch (className) {
    case 'TypesDeChampEditor':
      return import('components/TypesDeChampEditor').then(
        mod => mod.createReactUJSElement
      );
  }
}
