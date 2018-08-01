const _DATA = {};

function setupData() {
  if (window.DATA.length) {
    Object.assign(_DATA, ...window.DATA);
    window.DATA.length = 0;
  }
}

export function getData(namespace) {
  setupData();
  return namespace ? _DATA[namespace] : _DATA;
}
