import { useExplorerPlugin } from '@graphiql/plugin-explorer';
import { createGraphiQLFetcher } from '@graphiql/toolkit';
import { GraphiQL } from 'graphiql';
import { useState, createElement } from 'react';
import { createRoot } from 'react-dom/client';
import { z } from 'zod';

import 'graphiql/graphiql.css';
import '@graphiql/plugin-explorer/dist/style.css';

declare const window: Window & typeof globalThis & { gon: unknown };
const Gon = z.object({
  defaultQuery: z.string(),
  defaultVariables: z.string()
});
const { defaultQuery, defaultVariables } = Gon.parse(window.gon);

const fetcher = createGraphiQLFetcher({
  url: '/api/v2/graphql',
  headers: { 'x-csrf-token': csrfToken() ?? '' }
});

function GraphiQLWithExplorer() {
  const [query, setQuery] = useState(defaultQuery);
  const explorerPlugin = useExplorerPlugin({
    query,
    onEdit: setQuery
  });
  return createElement(GraphiQL, {
    fetcher,
    query,
    variables: defaultVariables,
    onEditQuery: setQuery,
    plugins: [explorerPlugin],
    defaultEditorToolsVisibility: true,
    isHeadersEditorEnabled: false
  });
}

const container = document.getElementById('graphiql');
if (container) {
  const root = createRoot(container);
  root.render(createElement(GraphiQLWithExplorer));
}

function csrfToken() {
  const meta = document.querySelector<HTMLMetaElement>('meta[name=csrf-token]');
  return meta?.content;
}
