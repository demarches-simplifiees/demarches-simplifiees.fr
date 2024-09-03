# frozen_string_literal: true

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

  def geometry
    object.geometry
  end

  def include_cadastre?
    object.source == GeoArea.sources.fetch(:cadastre)
  end
end
