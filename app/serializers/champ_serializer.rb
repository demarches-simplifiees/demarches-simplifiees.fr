class ChampSerializer < ActiveModel::Serializer
  include Rails.application.routes.url_helpers

  attributes :value

  has_one :type_de_champ

  def value
    case object
    when GeoArea, UserGeometry, Cadastre, QuartierPrioritaire
      object.geometry
    else
      if object.piece_justificative_file.attached?
        url_for(object.piece_justificative_file)
      else
        object.value
      end
    end
  end

  def type_de_champ
    case object
    when GeoArea, UserGeometry, Cadastre, QuartierPrioritaire
      legacy_type_de_champ
    else
      object.type_de_champ
    end
  end

  private

  def legacy_type_de_champ
    {
      id: -1,
      libelle: legacy_carto_libelle,
      type_champ: legacy_carto_type_champ,
      order_place: -1,
      descripton: ''
    }
  end

  def legacy_carto_libelle
    case object
    when UserGeometry, Cadastre, QuartierPrioritaire
      object.class.name.underscore.tr('_', ' ')
    else
      if object.source == GeoArea.sources.fetch(:selection_utilisateur)
        'user geometry'
      else
        object.source.to_s.tr('_', ' ')
      end
    end
  end

  def legacy_carto_type_champ
    case object
    when UserGeometry, Cadastre, QuartierPrioritaire
      object.class.name.underscore
    else
      if object.source == GeoArea.sources.fetch(:selection_utilisateur)
        'user_geometry'
      else
        object.source.to_s
      end
    end
  end
end
