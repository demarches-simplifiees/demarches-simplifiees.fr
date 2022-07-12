import Rails from '@rails/ujs';
import debounce from 'debounce';
import { session } from '@hotwired/turbo';
import { z } from 'zod';

export { debounce };
export const { fire, csrfToken, cspNonce } = Rails;

const Gon = z
  .object({
    autosave: z
      .object({
        debounce_delay: z.number().default(0),
        status_visible_duration: z.number().default(0)
      })
      .default({}),
    autocomplete: z
      .object({
        api_geo_url: z.string().optional(),
        api_adresse_url: z.string().optional(),
        api_education_url: z.string().optional()
      })
      .default({}),
    matomo: z
      .object({
        cookieDomain: z.string().optional(),
        domain: z.string().optional(),
        enabled: z.boolean().default(false),
        host: z.string().optional(),
        key: z.string().nullish()
      })
      .default({}),
    sentry: z
      .object({
        key: z.string().nullish(),
        enabled: z.boolean().default(false),
        environment: z.string().optional(),
        user: z.object({ id: z.string() }).default({ id: '' }),
        browser: z.object({ modern: z.boolean() }).default({ modern: false })
      })
      .default({}),
    crisp: z
      .object({
        key: z.string().nullish(),
        enabled: z.boolean().default(false),
        administrateur: z
          .object({
            email: z.string(),
            DS_SIGN_IN_COUNT: z.number(),
            DS_NB_DEMARCHES_BROUILLONS: z.number(),
            DS_NB_DEMARCHES_ACTIVES: z.number(),
            DS_NB_DEMARCHES_ARCHIVES: z.number(),
            DS_ID: z.number()
          })
          .default({
            email: '',
            DS_SIGN_IN_COUNT: 0,
            DS_NB_DEMARCHES_BROUILLONS: 0,
            DS_NB_DEMARCHES_ACTIVES: 0,
            DS_NB_DEMARCHES_ARCHIVES: 0,
            DS_ID: 0
          })
      })
      .default({})
  })
  .default({});
declare const window: Window & typeof globalThis & { gon: unknown };

export function getConfig() {
  return Gon.parse(window.gon);
}

export function show(el: HTMLElement | null) {
  el?.classList.remove('hidden');
}

export function hide(el: HTMLElement | null) {
  el?.classList.add('hidden');
}

export function toggle(el: HTMLElement | null, force?: boolean) {
  if (force == undefined) {
    el?.classList.toggle('hidden');
  } else if (force) {
    el?.classList.remove('hidden');
  } else {
    el?.classList.add('hidden');
  }
}

export function enable(el: HTMLInputElement | HTMLButtonElement | null) {
  el && (el.disabled = false);
}

export function disable(el: HTMLInputElement | HTMLButtonElement | null) {
  el && (el.disabled = true);
}

export function hasClass(el: HTMLElement | null, cssClass: string) {
  return el?.classList.contains(cssClass);
}

export function addClass(el: HTMLElement | null, cssClass: string) {
  el?.classList.add(cssClass);
}

export function removeClass(el: HTMLElement | null, cssClass: string) {
  el?.classList.remove(cssClass);
}

export function delegate<E extends Event = Event>(
  eventNames: string,
  selector: string,
  callback: (event: E) => void
) {
  eventNames
    .split(' ')
    .forEach((eventName) =>
      Rails.delegate(
        document,
        selector,
        eventName,
        callback as (event: Event) => void
      )
    );
}

export class ResponseError extends Error {
  readonly response: Response;
  readonly jsonBody?: unknown;
  readonly textBody?: string;

  constructor(response: Response, jsonBody?: unknown, textBody?: string) {
    super(String(response.statusText || response.status));
    this.response = response;
    this.jsonBody = jsonBody;
    this.textBody = textBody;
  }
}

const FETCH_TIMEOUT = 30 * 1000; // 30 sec

// Perform an HTTP request using `fetch` API,
// and handle the result depending on the MIME type.
//
// Usage:
//
// Execute a GET request, and return the response as parsed JSON
// const parsedJson = await httpRequest(url).json();
//
// Execute a POST request with some JSON payload
// const parsedJson = await httpRequest(url, { method: 'POST', json: '{ "foo": 1 }').json();
//
// Execute a GET request, and apply the Turbo stream in the Response
// await httpRequest(url).turbo();
//
export function httpRequest(
  url: string,
  {
    csrf = true,
    timeout = FETCH_TIMEOUT,
    json,
    controller,
    ...init
  }: RequestInit & {
    csrf?: boolean;
    json?: unknown;
    timeout?: number | false;
    controller?: AbortController;
  } = {}
) {
  const headers = init.headers ? new Headers(init.headers) : new Headers();
  if (csrf) {
    headers.set('x-csrf-token', csrfToken() ?? '');
    headers.set('x-requested-with', 'XMLHttpRequest');
    init.credentials = 'same-origin';
  }
  init.headers = headers;
  init.method = init.method?.toUpperCase() ?? 'GET';

  if (json) {
    headers.set('content-type', 'application/json');
    init.body = JSON.stringify(json);
  }

  let timer: ReturnType<typeof setTimeout>;
  if (!init.signal) {
    controller = createAbortController(controller);
    if (controller) {
      init.signal = controller.signal;
      if (timeout != false) {
        timer = setTimeout(() => controller?.abort(), timeout);
      }
    }
  }

  const request = async (
    init: RequestInit,
    accept?: string
  ): Promise<Response> => {
    if (accept && init.headers instanceof Headers) {
      init.headers.set('accept', accept);
    }
    try {
      const response = await fetch(url, init);

      if (response.ok) {
        return response;
      } else if (response.status == 401) {
        location.reload(); // reload whole page so Devise will redirect to sign-in
      }

      const contentType = response.headers.get('content-type');
      let jsonBody: unknown;
      let textBody: string | undefined;
      try {
        if (contentType?.match('json')) {
          jsonBody = await response.clone().json();
        } else {
          textBody = await response.clone().text();
        }
      } catch {
        // ignore
      }
      throw new ResponseError(response, jsonBody, textBody);
    } finally {
      clearTimeout(timer);
    }
  };

  return {
    async json<T>(): Promise<T | null> {
      const response = await request(init, 'application/json');
      if (response.status == 204) {
        return null;
      }
      return response.json();
    },
    async turbo(): Promise<void> {
      const response = await request(init, 'text/vnd.turbo-stream.html');
      if (response.status != 204) {
        const stream = await response.text();
        session.renderStreamMessage(stream);
      }
    },
    async js(): Promise<void> {
      const response = await request(init, 'text/javascript');
      if (response.status != 204) {
        const script = document.createElement('script');
        const nonce = cspNonce();
        if (nonce) {
          script.setAttribute('nonce', nonce);
        }
        script.text = await response.text();
        document.head.appendChild(script);
        document.head.removeChild(script);
      }
    }
  };
}

function createAbortController(controller?: AbortController) {
  if (controller) {
    return controller;
  } else if (window.AbortController) {
    return new AbortController();
  }
  return;
}

export function isNumeric(s: string) {
  const n = parseFloat(s);
  return !isNaN(n) && isFinite(n);
}

export function isSelectElement(
  element: HTMLElement
): element is HTMLSelectElement {
  return element.tagName == 'SELECT';
}

export function isCheckboxOrRadioInputElement(
  element: HTMLElement & { type?: string }
): element is HTMLInputElement {
  return (
    element.tagName == 'INPUT' &&
    (element.type == 'checkbox' || element.type == 'radio')
  );
}

export function isTextInputElement(
  element: HTMLElement & { type?: string }
): element is HTMLInputElement {
  return (
    ['INPUT', 'TEXTAREA'].includes(element.tagName) &&
    element.type != 'checkbox' &&
    element.type != 'radio'
  );
}
