declare module '@tmcw/togeojson' {
  import { FeatureCollection, GeoJsonProperties, Geometry } from 'geojson';

  export function kml(doc: Document): FeatureCollection;

  export function kml<TProperties extends GeoJsonProperties>(
    doc: Document
  ): FeatureCollection<Geometry, TProperties>;

  export function gpx(doc: Document): FeatureCollection;
  export function gpx<TProperties extends GeoJsonProperties>(
    doc: Document
  ): FeatureCollection<Geometry, TProperties>;

  export function tcx(doc: Document): FeatureCollection;
  export function tcx<TProperties extends GeoJsonProperties>(
    doc: Document
  ): FeatureCollection<Geometry, TProperties>;
}

declare module 'react-coordinate-input';
