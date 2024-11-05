# frozen_string_literal: true

module DossierEmptyConcern
  extend ActiveSupport::Concern

  included do
    scope :empty_brouillon, -> (created_at) do
      dossiers_ids = Dossier.brouillon.where(created_at:).ids

      dossiers_with_value = Dossier.select('id').includes(:champs)
        .where.not(champs: { value: nil })
        .where(id: dossiers_ids)

      dossier_with_geo_areas = Dossier.select('id').includes(champs: :geo_areas)
        .where.not(geo_areas: { id: nil })
        .where(id: dossiers_ids)

      dossier_with_pj = Dossier.select('id')
        .joins(champs: :piece_justificative_file_attachments)
        .where(id: dossiers_ids)

      brouillon
        .where.not(id: dossiers_with_value)
        .where.not(id: dossier_with_geo_areas)
        .where.not(id: dossier_with_pj)
        .where(id: dossiers_ids)
    end
  end
end
