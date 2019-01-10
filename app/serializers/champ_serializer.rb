class ChampSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :value

  has_one :type_de_champ

  has_many :geo_areas, if: :include_geo_areas?
  has_one :etablissement, if: :include_etablissement?
  has_one :entreprise, if: :include_etablissement?

  def value
    case object
    when GeoArea
      object.geometry
    else
      object.for_api
    end
  end

  def type_de_champ
    case object
    when GeoArea
      legacy_type_de_champ
    else
      object.type_de_champ
    end
  end

  def etablissement
    object.etablissement
  end

  def entreprise
    object.etablissement&.entreprise
  end

  def include_etablissement?
    object.is_a?(Champs::SiretChamp)
  end

  def include_geo_areas?
    object.is_a?(Champs::CarteChamp)
  end

  private

  def legacy_type_de_champ
    {
      id: -1,
      libelle: legacy_carto_libelle,
      type_champ: legacy_carto_type_champ,
      order_place: -1,
      description: ''
    }
  end

  def legacy_carto_libelle
    if object.source == GeoArea.sources.fetch(:selection_utilisateur)
      'user geometry'
    else
      object.source.to_s.tr('_', ' ')
    end
  end

  def legacy_carto_type_champ
    if object.source == GeoArea.sources.fetch(:selection_utilisateur)
      'user_geometry'
    else
      object.source.to_s
    end
  end
end
