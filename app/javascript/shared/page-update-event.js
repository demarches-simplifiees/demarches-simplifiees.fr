import { fire } from '@utils';

addEventListener('DOMContentLoaded', function () {
  fire(document, 'ds:page:update');
});

addEventListener('ajax:success', function () {
  fire(document, 'ds:page:update');
});
