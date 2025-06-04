# frozen_string_literal: true

module Types
  class AddressType < Types::BaseObject
    class AddressTypeType < Types::BaseEnum
      value(:housenumber, "numéro « à la plaque »", value: "housenumber")
      value(:street, "position « à la voie », placé approximativement au centre de celle-ci", value: "street")
      value(:municipality, "numéro « à la commune »", value: "municipality")
      value(:locality, "lieu-dit", value: "locality")
    end

    field :label, String, "libellé complet de l’adresse", null: false
    field :type, AddressTypeType, "type de résultat trouvé", null: false

    field :street_address, String, "numéro éventuel et nom de voie ou lieu dit", null: true
    field :street_number, String, "numéro avec indice de répétition éventuel (bis, ter, A, B)", null: true
    field :street_name, String, "nom de voie ou lieu dit", null: true

    field :postal_code, String, "code postal", null: false
    field :city_name, String, "nom de la commune", null: false
    field :city_code, String, "code INSEE de la commune", null: false

    field :department_name, String, "nom de département", null: true
    field :department_code, String, "n° de département", null: true

    field :region_name, String, "nom de région", null: true
    field :region_code, String, "n° de région", null: true

    field :geometry, Types::GeoJSON, "coordonnées géographique", null: true

    def city_name
      APIGeoService.safely_normalize_city_name(
        object['department_code'],
        object['city_code'],
        object['city_name']
      )
    end

    def department_name
      if object['department_code'].present?
        APIGeoService.departement_name(object.fetch('department_code'))
      else
        object['department_name']
      end
    end

    def region_name
      if object['region_code'].present?
        APIGeoService.region_name(object.fetch('region_code'))
      else
        object['region_name']
      end
    end
  end
end
