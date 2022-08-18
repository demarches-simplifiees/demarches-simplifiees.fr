// This file contains type definitions for untyped packages. We are lucky to have only two ;)

declare module '@tmcw/togeojson/dist/togeojson.es.js' {
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
declare module 'chartkick';
declare module 'trix';
declare module '@rails/actiontext';
