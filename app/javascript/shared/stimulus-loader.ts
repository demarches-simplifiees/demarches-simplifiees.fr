import { Application } from '@hotwired/stimulus';
import invariant from 'tiny-invariant';

const controllers = import.meta.globEager('../controllers/*.{ts,tsx}');

export function registerControllers(application: Application) {
  for (const [path, mod] of Object.entries(controllers)) {
    const [filename] = path.split('/').reverse();
    const name = filename
      .replace(/_/g, '-')
      .replace(/-controller\.(ts|tsx)$/, '');
    if (name != 'application') {
      if (mod.default) {
        console.debug(`Registered default export for "${name}" controller`);
        application.register(name, mod.default);
      } else {
        const exports = Object.entries(mod);
        invariant(
          exports.length == 1,
          `Expected a single export but ${exports.length} exports were found for "${name}" controller`
        );
        const [exportName, exportMod] = exports[0];
        console.debug(
          `Registered named export "${exportName}" for "${name}" controller`
        );
        application.register(name, exportMod);
      }
    }
  }
}
