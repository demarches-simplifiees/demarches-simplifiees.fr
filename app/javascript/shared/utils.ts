import Rails from '@rails/ujs';
import debounce from 'debounce';
import { session } from '@hotwired/turbo';

export { debounce };
export const { fire, csrfToken, cspNonce } = Rails;

export function show(el: HTMLElement) {
  el && el.classList.remove('hidden');
}

export function hide(el: HTMLElement) {
  el && el.classList.add('hidden');
}

export function toggle(el: HTMLElement, force?: boolean) {
  if (force == undefined) {
    el && el.classList.toggle('hidden');
  } else if (force) {
    el && el.classList.remove('hidden');
  } else {
    el && el.classList.add('hidden');
  }
}

export function enable(el: HTMLInputElement) {
  el && (el.disabled = false);
}

export function disable(el: HTMLInputElement) {
  el && (el.disabled = true);
}

export function hasClass(el: HTMLElement, cssClass: string) {
  return el && el.classList.contains(cssClass);
}

export function addClass(el: HTMLElement, cssClass: string) {
  el && el.classList.add(cssClass);
}

export function removeClass(el: HTMLElement, cssClass: string) {
  el && el.classList.remove(cssClass);
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

// A promise-based wrapper for Rails.ajax().
//
// Returns a Promise that is either:
// - resolved in case of a 20* HTTP response code,
// - rejected with an Error object otherwise.
//
// See Rails.ajax() code for more details.
export function ajax(options: Rails.AjaxOptions) {
  return new Promise((resolve, reject) => {
    Object.assign(options, {
      success: (
        response: unknown,
        statusText: string,
        xhr: { status: number }
      ) => {
        resolve({ response, statusText, xhr });
      },
      error: (
        response: unknown,
        statusText: string,
        xhr: { status: number }
      ) => {
        // NB: on HTTP/2 connections, statusText is always empty.
        const error = new Error(
          `Erreur ${xhr.status}` + (statusText ? ` : ${statusText}` : '')
        );
        Object.assign(error, { response, statusText, xhr });
        reject(error);
      }
    });
    Rails.ajax(options);
  });
}

export class ResponseError extends Error {
  response: Response;

  constructor(response: Response) {
    super(String(response.statusText || response.status));
    this.response = response;
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
// Execute a GET request, and interpret the JavaScript code in the Response
// DEPRECATED: Don't use this in new code; instead let the server respond with a turbo stream
// await httpRequest(url).js();
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

  let timer: number;
  if (!init.signal) {
    controller = createAbortController(controller);
    if (controller) {
      init.signal = controller.signal;
      if (timeout != false) {
        timer = setTimeout(() => controller?.abort(), timeout);
      }
    }
  }

  const request = (init: RequestInit, accept?: string): Promise<Response> => {
    if (accept && init.headers instanceof Headers) {
      init.headers.set('accept', accept);
    }
    return fetch(url, init)
      .then((response) => {
        clearTimeout(timer);

        if (response.ok) {
          return response;
        } else if (response.status == 401) {
          location.reload(); // reload whole page so Devise will redirect to sign-in
        }
        throw new ResponseError(response);
      })
      .catch((error) => {
        clearTimeout(timer);

        throw error;
      });
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

export function scrollTo(container: HTMLElement, scrollTo: HTMLElement) {
  container.scrollTop =
    offset(scrollTo).top - offset(container).top + container.scrollTop;
}

export function scrollToBottom(container: HTMLElement) {
  container.scrollTop = container.scrollHeight;
}

export function on(
  selector: string,
  eventName: string,
  fn: (event: Event, detail: unknown) => void
) {
  [...document.querySelectorAll(selector)].forEach((element) =>
    element.addEventListener(eventName, (event) =>
      fn(event, (event as CustomEvent).detail)
    )
  );
}

export function isNumeric(s: string) {
  const n = parseFloat(s);
  return !isNaN(n) && isFinite(n);
}

function offset(element: HTMLElement) {
  const rect = element.getBoundingClientRect();
  return {
    top: rect.top + document.body.scrollTop,
    left: rect.left + document.body.scrollLeft
  };
}

// Takes a promise, and return a promise that times out after the given delay.
export function timeoutable<T>(
  promise: Promise<T>,
  timeoutDelay: number
): Promise<T> {
  const timeoutPromise = new Promise<T>((resolve, reject) => {
    setTimeout(() => {
      reject(new Error(`Promise timed out after ${timeoutDelay}ms`));
    }, timeoutDelay);
  });
  return Promise.race([promise, timeoutPromise]);
}
