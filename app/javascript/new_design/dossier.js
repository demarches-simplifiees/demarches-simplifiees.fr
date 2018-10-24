import { throttle } from '@utils';

let footerHeight;

function scrollDossier() {
  const height = document.body.scrollHeight;
  const scrollY = window.scrollY;

  let bottom = height - (scrollY + window.innerHeight) - footerHeight;
  bottom = bottom >= 0 ? 0 : -bottom;

  document.querySelector('.send-wrapper').style.bottom = `${bottom}px`;
}

addEventListener('turbolinks:load', () => {
  const statusbar = document.querySelector('.dossier-edit .send-wrapper');
  const footer = document.querySelector('.dossier-footer');

  if (statusbar && footer) {
    footerHeight = footer.offsetHeight;
    addEventListener('resize', throttle(200, scrollDossier));
    addEventListener('scroll', scrollDossier);
  }
});

function updateFileInputs(html) {
  let parser = new DOMParser();
  let doc = parser.parseFromString(html, 'text/html');
  let inputs = [
    ...doc.querySelectorAll('.editable-champ-piece_justificative')
  ].map(element => [
    element.querySelector('input').getAttribute('id'),
    element.innerHTML
  ]);
  for (let [id, html] of inputs) {
    document.getElementById(id).closest('.editable-champ').innerHTML = html;
  }
  document.querySelector(
    '.dossier-last-saved-at'
  ).innerHTML = doc.querySelector('.dossier-last-saved-at').innerHTML;
}

addEventListener('turbolinks:load', () => {
  window.DS.updateFileInputs = updateFileInputs;
});
