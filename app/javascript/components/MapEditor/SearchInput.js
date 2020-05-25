import React, { useState, useEffect } from 'react';
import { getJSON } from '@utils';
import {
  Combobox,
  ComboboxInput,
  ComboboxPopover,
  ComboboxList,
  ComboboxOption
} from '@reach/combobox';
import '@reach/combobox/styles.css';
import PropTypes from 'prop-types';

let cache = {};
const useAddressSearch = (searchTerm) => {
  const [addresses, setAddresses] = useState([]);
  useEffect(() => {
    if (searchTerm.trim() !== '') {
      let isFresh = true;
      fetchAddresses(searchTerm).then((addresses) => {
        if (isFresh) setAddresses(addresses);
      });
      return () => (isFresh = false);
    }
  }, [searchTerm]);
  return addresses;
};

const fetchAddresses = (value) => {
  if (cache[value]) {
    return Promise.resolve(cache[value]);
  }
  const url = `https://api-adresse.data.gouv.fr/search/`;
  return getJSON(url, { q: value, limit: 5 }, 'get').then((result) => {
    if (result) {
      cache[value] = result;
    }
    return result;
  });
};

const SearchInput = ({ getCoords }) => {
  const [searchTerm, setSearchTerm] = useState('');
  const addresses = useAddressSearch(searchTerm);
  const handleSearchTermChange = (event) => {
    setSearchTerm(event.target.value);
  };
  return (
    <Combobox aria-label="addresses">
      <ComboboxInput
        placeholder="Rechercher une adresse : saisissez au moins 2 caractères"
        className="address-search-input"
        style={{
          font: 'inherit',
          padding: '.25rem .5rem',
          width: '100%',
          minHeight: '62px'
        }}
        onChange={handleSearchTermChange}
      />
      {addresses.features && (
        <ComboboxPopover className="shadow-popup">
          {addresses.features.length > 0 ? (
            <ComboboxList>
              {addresses.features.map((feature) => {
                const str = `${feature.properties.name}, ${feature.properties.city}`;
                return (
                  <ComboboxOption
                    onClick={() => getCoords(feature.geometry.coordinates)}
                    key={str}
                    value={str}
                  />
                );
              })}
            </ComboboxList>
          ) : (
            <span style={{ display: 'block', margin: 8 }}>Aucun résultat</span>
          )}
        </ComboboxPopover>
      )}
    </Combobox>
  );
};

SearchInput.propTypes = {
  getCoords: PropTypes.func
};

export default SearchInput;
