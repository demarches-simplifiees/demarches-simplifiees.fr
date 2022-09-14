export function closeNoticeInfo(event) {
  // DSFR usptream code
  const notice = event.target.parentNode.parentNode.parentNode;
  notice.parentNode.removeChild(notice);

  // Update class accordingly because
  // header style is slightly different with or without notice
  if (document.querySelector) {
    const klass = 'fr-header__with-notice-info';
    const header = document.querySelector('.' + klass);

    if (header) {
      header.classList.remove(klass);
    }
  }
}
