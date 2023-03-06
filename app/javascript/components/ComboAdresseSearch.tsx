import React from 'react';
import { QueryClientProvider } from 'react-query';
import type { FeatureCollection, Geometry } from 'geojson';

import ComboSearch, { ComboSearchProps } from './ComboSearch';
import { queryClient } from './shared/queryClient';

type RawResult = FeatureCollection<Geometry, { label: string }>;
type AdresseResult = RawResult['features'][0];
type ComboAdresseSearchProps = Omit<
  ComboSearchProps<AdresseResult>,
  'minimumInputLength' | 'transformResult' | 'transformResults' | 'scope'
>;

export default function ComboAdresseSearch({
  allowInputValues = true,
  ...props
}: ComboAdresseSearchProps) {
  return (
    <QueryClientProvider client={queryClient}>
      <ComboSearch<AdresseResult>
        {...props}
        allowInputValues={allowInputValues}
        scope="adresse"
        minimumInputLength={2}
        transformResult={({ properties: { label } }) => [label, label, label]}
        transformResults={(_, result) => (result as RawResult).features}
        debounceDelay={300}
      />
    </QueryClientProvider>
  );
}
