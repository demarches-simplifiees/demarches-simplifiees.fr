import { ApplicationController } from './application_controller';

const LAST_TAB = 'instructeur-dossier-navigation.lastTab';

export class InstructeurDossierNavigationController extends ApplicationController {
  connect(): void {
    this.onGlobal('turbo:load', () => {
      this.match();
    });
  }

  private match() {
    if (DOSSIER_LIST_PAGE.test(location.pathname)) {
      dossierListPage();
    } else if (DOSSIER_SHOW_PAGE.test(location.pathname)) {
      dossierShowPage();
    } else {
      catchAll();
    }
  }
}

function dossierListPage() {
  destroyObserver();
  const params = getParams();
  const statut = params.get('statut');
  if (!statut) {
    sessionStorage.removeItem(LAST_TAB);
  } else {
    rewriteDossierLinks(statut);
    sessionStorage.setItem(LAST_TAB, statut);
  }
}

function dossierShowPage() {
  destroyObserver();
  const params = getParams();
  const statut = sessionStorage.getItem(LAST_TAB) ?? params.get('statut');
  if (!statut) {
    sessionStorage.removeItem(LAST_TAB);
  } else {
    rewriteBackLinks(statut);
    rewriteDossierLinks(statut);
    createObserver(statut);
    sessionStorage.setItem(LAST_TAB, statut);
  }
}

function catchAll() {
  destroyObserver();
  sessionStorage.removeItem(LAST_TAB);
}

function getParams() {
  return new URL(location.href).searchParams;
}

function rewriteBackLinks(statut: string) {
  document
    .querySelectorAll('a')
    .forEach((link) => rewriteLink(link, statut, DOSSIER_LIST_PAGE));
}

function rewriteDossierLinks(statut: string) {
  document
    .querySelectorAll('a')
    .forEach((link) => rewriteLink(link, statut, DOSSIER_SHOW_PAGE));
}

function rewriteLink(link: HTMLAnchorElement, statut: string, regexp: RegExp) {
  const url = new URL(link.href, location.href);
  if (regexp.test(url.pathname)) {
    url.searchParams.set('statut', statut);
    link.href = url.href;
  }
}

const DOSSIER_LIST_PAGE = /^\/procedures\/\d+\/?$/;
const DOSSIER_SHOW_PAGE = /^\/procedures\/\d+\/dossiers\/.*$/;

let observer: MutationObserver | null = null;
function destroyObserver() {
  observer?.disconnect();
  observer = null;
}
function createObserver(statut: string) {
  observer = new MutationObserver((mutationsList) => {
    for (const mutation of mutationsList) {
      if (mutation.type === 'childList') {
        mutation.addedNodes.forEach((node) => {
          if (node instanceof HTMLAnchorElement) {
            rewrite(node);
          }
        });
      } else if (
        mutation.type == 'attributes' &&
        mutation.attributeName == 'href' &&
        mutation.target instanceof HTMLAnchorElement
      ) {
        rewrite(mutation.target);
      }
    }
  });
  const config = {
    childList: true,
    subtree: true,
    attributes: true,
    attributeFilter: ['href']
  };
  const observe = () => observer?.observe(document.body, config);
  const rewrite = (link: HTMLAnchorElement) => {
    observer?.disconnect();
    rewriteLink(link, statut, DOSSIER_LIST_PAGE);
    observe();
  };
  observe();
}
