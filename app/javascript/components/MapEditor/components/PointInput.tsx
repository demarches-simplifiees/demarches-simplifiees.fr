import { useState, useId } from 'react';
import { fire } from '@utils';
import type { Feature, FeatureCollection } from 'geojson';
import CoordinateInput from 'react-coordinate-input';

export function PointInput({
  featureCollection,
  translations
}: {
  featureCollection: FeatureCollection;
  translations: Record<string, string>;
}) {
  const inputId = useId();
  const [value, setValue] = useState('');
  const [feature, setFeature] = useState<Feature | null>(null);
  const getCurrentPosition = () => {
    navigator.geolocation?.getCurrentPosition(({ coords }) => {
      setValue(
        `${coords.latitude.toPrecision(6)}, ${coords.longitude.toPrecision(6)}`
      );
    });
  };
  const addPoint = () => {
    if (feature) {
      fire(document, 'map:feature:create', {
        feature,
        featureCollection
      });
      setValue('');
      setFeature(null);
    }
  };

  return (
    <div className="fr-input-group fr-mt-3w">
      <label className="fr-label" htmlFor={inputId}>
        {translations.pin_input_label}
        <span className="fr-hint-text">
          {translations.pin_input_description}
          43°48&#39;06&#34;N 006°14&#39;59&#34;E
        </span>
      </label>
      <div className="flex flex-gap-1 fr-mt-1w">
        {navigator.geolocation ? (
          <button
            type="button"
            className="fr-btn fr-btn--secondary fr-icon-map-pin-2-line"
            onClick={getCurrentPosition}
            title={translations.show_pin}
          >
            <span className="sr-only">{translations.show_pin}</span>
          </button>
        ) : null}
        <CoordinateInput
          id={inputId}
          className="fr-input"
          value={value}
          onChange={(value: string, { dd }: { dd: [number, number] }) => {
            setValue(value);
            if (dd.length) {
              const coordinates: [number, number] = [dd[1], dd[0]];
              const feature = {
                type: 'Feature' as const,
                geometry: { type: 'Point' as const, coordinates },
                properties: {}
              };
              setFeature(feature);
              fire(document, 'map:zoom', { featureCollection, feature });
            } else {
              setFeature(null);
            }
          }}
        />
        <button
          type="button"
          className="fr-btn fr-icon-add-circle-line"
          onClick={addPoint}
          disabled={!feature}
          title={translations.add_pin}
        >
          <span className="sr-only">{translations.add_pin}</span>
        </button>
      </div>
    </div>
  );
}
