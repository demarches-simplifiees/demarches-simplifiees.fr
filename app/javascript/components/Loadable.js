import React, { Suspense, lazy } from 'react';
import PropTypes from 'prop-types';

const Loader = () => <div className="spinner left" />;

function LazyLoad({ component: Component, ...props }) {
  return (
    <Suspense fallback={<Loader />}>
      <Component {...props} />
    </Suspense>
  );
}

LazyLoad.propTypes = {
  component: PropTypes.object
};

export default function Loadable(loader) {
  const LazyComponent = lazy(loader);

  return function PureComponent(props) {
    return <LazyLoad component={LazyComponent} {...props} />;
  };
}
