import React from 'react';
import Loadable from 'react-loadable';

const loading = () => <div className="spinner left" />;

export default function (loader) {
  return Loadable({ loader, loading });
}
