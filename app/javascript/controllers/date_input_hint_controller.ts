import { ApplicationController } from './application_controller';

const DATE_PLACEHOLDER_REGEXP = /[jJmMdD]{2}\/[jJmMdD]{2}\/[aAyY]{4}/;
const DATE_EXAMPLE_REGEXP = /\d{1,2}\/\d{1,2}\/\d{4}/;
const PARTS = {
  fr: {
    '15': 'JJ',
    '10': 'MM',
    '2022': 'AAAA'
  },
  en: {
    '15': 'dd',
    '10': 'mm',
    '2022': 'yyyy'
  }
};

export class DateInputHintController extends ApplicationController {
  connect() {
    this.fixDateFormat(this.element);
  }

  private fixDateFormat(input: Element) {
    const text = input.textContent ?? '';
    const match = text.match(DATE_PLACEHOLDER_REGEXP);

    if (match) {
      const [placeholder, example] = this.translatePlaceholder();
      // This component behaviour can be had to test and debug. We keep a (debug) log here to help.
      console.debug(`Replace ${match[0]} with ${placeholder} and ${example}`);
      input.textContent = text
        .replace(DATE_PLACEHOLDER_REGEXP, placeholder)
        .replace(DATE_EXAMPLE_REGEXP, example);
    }
  }

  private translatePlaceholder() {
    const locale = document.documentElement.lang as 'fr' | 'en';
    const parts = PARTS[locale];
    const example = new Date(2022, 9, 15).toLocaleDateString();
    return [
      Object.entries(parts).reduce(
        (text, [part, str]) => text.replace(part, str),
        example
      ),
      example
    ];
  }
}
