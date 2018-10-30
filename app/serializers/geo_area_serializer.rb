class GeoAreaSerializer < ActiveModel::Serializer
  attributes :geometry, :source, :geo_reference_id

  attribute :surface_intersection, if: :include_cadastre?
  attribute :surface_parcelle, if: :include_cadastre?
  attribute :numero, if: :include_cadastre?
  attribute :feuille, if: :include_cadastre?
  attribute :section, if: :include_cadastre?
  attribute :code_dep, if: :include_cadastre?
  attribute :nom_com, if: :include_cadastre?
  attribute :code_com, if: :include_cadastre?
  attribute :code_arr, if: :include_cadastre?

  attribute :code, if: :include_quartier_prioritaire?
  attribute :nom, if: :include_quartier_prioritaire?
  attribute :commune, if: :include_quartier_prioritaire?

  attribute :culture, if: :include_parcelle_agricole?
  attribute :code_culture, if: :include_parcelle_agricole?
  attribute :surface, if: :include_parcelle_agricole?
  attribute :bio, if: :include_parcelle_agricole?

  def include_cadastre?
    object.source == GeoArea.sources.fetch(:cadastre)
  end

  def include_quartier_prioritaire?
    object.source == GeoArea.sources.fetch(:quartier_prioritaire)
  end

  def include_parcelle_agricole?
    object.source == GeoArea.sources.fetch(:parcelle_agricole)
  end
end
