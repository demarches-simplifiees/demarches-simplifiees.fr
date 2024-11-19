# frozen_string_literal: true

class DossierProjectionService
  class DossierProjection < Struct.new(:dossier, :corrections, :columns) do
      def pending_correction?
        return false if corrections.blank?

        corrections.any?(&:nil?)
      end

      def resolved_corrections?
        return false if corrections.blank?

        corrections.all?(&:present?)
      end
    end
  end

  def self.project(dossier_ids, columns)
    dossiers = Dossier.find(dossier_ids)
    corrections_for = corrections_by_dossier_id(dossier_ids)

    # each project should return
    # { dossier_id => { column_id => value, column_id2 ... }, dossier_id2 ... }
    projection = columns.group_by(&:projector)
      .map { |p, columns| p.project(columns, dossiers) }
      .reduce(:deep_merge)

    dossiers.map do |dossier|
      DossierProjection.new(
        dossier,
        corrections_for[dossier.id],
        columns.map { |column| projection[dossier.id][column.id] }
      )
    end
  end

  private

  def self.corrections_by_dossier_id(dossier_ids)
    DossierCorrection.where(dossier_id: dossier_ids)
      .pluck(:dossier_id, :resolved_at)
      .each_with_object(Hash.new { |h, k| h[k] = [] }) do |(dossier_id, resolved_at), h|
        h[dossier_id] << resolved_at
      end
  end
end
