import { explorerPlugin } from '@graphiql/plugin-explorer';
import { createGraphiQLFetcher } from '@graphiql/toolkit';
import { GraphiQL } from 'graphiql';
import { createElement, useState } from 'react';
import { createRoot } from 'react-dom/client';

import { csrfToken, getConfig } from '@utils';

import '@graphiql/plugin-explorer/style.css';
import 'graphiql/graphiql.css';

const { defaultQuery, defaultVariables } = getConfig();
const fetcher = createGraphiQLFetcher({
  url: '/api/v2/graphql',
  headers: { 'x-csrf-token': csrfToken() ?? '' }
});

function GraphiQLWithExplorer() {
  const [query, setQuery] = useState(defaultQuery);
  const explorer = explorerPlugin({ showAttribution: false });
  return createElement(GraphiQL, {
    fetcher: fetcher,
    defaultEditorToolsVisibility: true,
    plugins: [explorer],
    query: query,
    variables: defaultVariables,
    onEditQuery: setQuery
  });
}

const element = document.getElementById('playground');
if (element) {
  const root = createRoot(element);
  root.render(createElement(GraphiQLWithExplorer));
}
