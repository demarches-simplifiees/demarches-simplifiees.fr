# frozen_string_literal: true

class DossierProjectionService
  class DossierProjection < Struct.new(:dossier, :dossier_id, :prenom, :nom, :corrections, :columns) do
      def pending_correction?
        return false if corrections.blank?

        corrections.any? { _1[:resolved_at].nil? }
      end

      def resolved_corrections?
        return false if corrections.blank?

        corrections.all? { _1[:resolved_at].present? }
      end
    end
  end

  TABLE = 'table'
  COLUMN = 'column'
  STABLE_ID = 'stable_id'

  # Returns [DossierProjection(dossier, columns)] ordered by dossiers_ids
  # and the columns orderd by fields.
  #
  # It tries to be fast by using `pluck` (or at least `select`)
  # to avoid deserializing entire records.
  #
  # It stores its intermediary queries results in an hash in the corresponding field.
  # ex: field_email[:id_value_h] = { dossier_id_1: email_1, dossier_id_3: email_3 }
  #
  # Those hashes are needed because:
  # - the order of the intermediary query results are unknown
  # - some values can be missing (if a revision added or removed them)
  def self.project(dossier_ids, columns)
    tableau = Tableau.new(dossier_ids, columns)
    tableau.dossiers = Dossier.find(dossier_ids)

    columns.group_by(&:loader).map do |loader, columns|
      tableau.add_data(loader.load(columns, tableau.dossiers))
    end

    # on charge toujours les corrections
    tableau.corrections_by_dossier_id = corrections_by_dossier_id(dossier_ids)

    tableau
  end

  private

  def self.corrections_by_dossier_id(dossier_ids)
    DossierCorrection.where(dossier_id: dossier_ids)
      .pluck(:dossier_id, :resolved_at)
      .group_by(&:first) # group corrections by dossier_id
      .transform_values do |dossier_id_resolved_ats| # build each correction has an hash column => value
        dossier_id_resolved_ats.map { |_, resolved_at| resolved_at }
      end
  end
end
