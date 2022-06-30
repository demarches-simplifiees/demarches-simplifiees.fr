import type { AxeResults, NodeResult, RelatedNode } from 'axe-core';
import axe from 'axe-core';

domReady().then(() => {
  axe.run(document.body, { reporter: 'v2' }).then((results) => {
    logToConsole(results);
  });
});

// contrasted against Chrome default color of #ffffff
const lightTheme = {
  serious: '#d93251',
  minor: '#d24700',
  text: 'black'
};

// contrasted against Safari dark mode color of #535353
const darkTheme = {
  serious: '#ffb3b3',
  minor: '#ffd500',
  text: 'white'
};

const theme =
  window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches
    ? darkTheme
    : lightTheme;

const boldCourier = 'font-weight:bold;font-family:Courier;';
const critical = `color:${theme.serious};font-weight:bold;`;
const serious = `color:${theme.serious};font-weight:normal;`;
const moderate = `color:${theme.minor};font-weight:bold;`;
const minor = `color:${theme.minor};font-weight:normal;`;
const defaultReset = `font-color:${theme.text};font-weight:normal;`;

function logToConsole(results: AxeResults): void {
  console.group('%cNew axe issues', serious);
  results.violations.forEach((result) => {
    let fmt: string;
    switch (result.impact) {
      case 'critical':
        fmt = critical;
        break;
      case 'serious':
        fmt = serious;
        break;
      case 'moderate':
        fmt = moderate;
        break;
      case 'minor':
        fmt = minor;
        break;
      default:
        fmt = minor;
        break;
    }
    console.groupCollapsed(
      '%c%s: %c%s %s',
      fmt,
      result.impact,
      defaultReset,
      result.help,
      result.helpUrl
    );
    result.nodes.forEach((node) => {
      failureSummary(node, 'any');
      failureSummary(node, 'none');
    });
    console.groupEnd();
  });
  console.groupEnd();
}

function failureSummary(node: NodeResult, key: AxeCoreNodeResultKey): void {
  if (node[key].length > 0) {
    logElement(node, console.groupCollapsed);
    logHtml(node);
    logFailureMessage(node, key);

    let relatedNodes: RelatedNode[] = [];
    node[key].forEach((check) => {
      relatedNodes = relatedNodes.concat(check.relatedNodes ?? []);
    });

    if (relatedNodes.length > 0) {
      console.groupCollapsed('Related nodes');
      relatedNodes.forEach((relatedNode) => {
        logElement(relatedNode, console.log);
        logHtml(relatedNode);
      });
      console.groupEnd();
    }

    console.groupEnd();
  }
}

function logFailureMessage(node: NodeResult, key: AxeCoreNodeResultKey): void {
  // this exists on axe but we don't export it as part of the typescript
  // namespace, so just let me use it as I need
  const message: string = (
    axe as unknown as AxeWithAudit
  )._audit.data.failureSummaries[key].failureMessage(
    node[key].map((check) => check.message || '')
  );

  console.error(message);
}

function logElement(
  node: NodeResult | RelatedNode,
  logFn: (...args: unknown[]) => void
): void {
  const el = document.querySelector(node.target.toString());
  if (!el) {
    logFn('Selector: %c%s', boldCourier, node.target.toString());
  } else {
    logFn('Element: %o', el);
  }
}

function logHtml(node: NodeResult | RelatedNode): void {
  console.log('HTML: %c%s', boldCourier, node.html);
}

type AxeCoreNodeResultKey = 'any' | 'all' | 'none';

interface AxeWithAudit {
  _audit: {
    data: {
      failureSummaries: {
        any: {
          failureMessage: (args: string[]) => string;
        };
        all: {
          failureMessage: (args: string[]) => string;
        };
        none: {
          failureMessage: (args: string[]) => string;
        };
      };
    };
  };
}

function domReady() {
  return new Promise<void>((resolve) => {
    if (document.readyState == 'loading') {
      document.addEventListener('DOMContentLoaded', () => resolve(), {
        once: true
      });
    } else {
      resolve();
    }
  });
}
