import React, { useState, useId } from 'react';
import { fire } from '@utils';
import type { Feature } from 'geojson';
import { PlusIcon, LocationMarkerIcon } from '@heroicons/react/outline';
import CoordinateInput from 'react-coordinate-input';

export function PointInput() {
  const inputId = useId();
  const [value, setValue] = useState('');
  const [feature, setFeature] = useState<Feature | null>(null);
  const getCurrentPosition = () => {
    navigator.geolocation &&
      navigator.geolocation.getCurrentPosition(({ coords }) => {
        setValue(
          `${coords.latitude.toPrecision(6)}, ${coords.longitude.toPrecision(
            6
          )}`
        );
      });
  };
  const addPoint = () => {
    if (feature) {
      fire(document, 'map:feature:create', feature);
      setValue('');
      setFeature(null);
    }
  };

  return (
    <>
      <label
        className="areas-title mt-1"
        htmlFor={inputId}
        style={{ fontSize: '16px' }}
      >
        Ajouter un point sur la carte
      </label>
      <div className="flex align-center mt-1 mb-2">
        {navigator.geolocation ? (
          <button
            type="button"
            className="button mr-1"
            onClick={getCurrentPosition}
            title="Afficher votre position sur la carte"
          >
            <span className="sr-only">
              Afficher votre position sur la carte
            </span>
            <LocationMarkerIcon className="icon-size-big" aria-hidden />
          </button>
        ) : null}
        <CoordinateInput
          id={inputId}
          className="m-0 mr-1"
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
              fire(document, 'map:zoom', { feature });
            } else {
              setFeature(null);
            }
          }}
        />
        <button
          type="button"
          className="button"
          onClick={addPoint}
          disabled={!feature}
          title="Ajouter le point avec les coordonnées saisies sur la carte"
        >
          <span className="sr-only">
            Ajouter le point avec les coordonnées saisies sur la carte
          </span>
          <PlusIcon className="icon-size-big" aria-hidden />
        </button>
      </div>
    </>
  );
}
