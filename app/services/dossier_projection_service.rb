# frozen_string_literal: true

class DossierProjectionService
  class DossierProjection < Struct.new(:dossier, :columns)
  end

  def self.project(dossier_ids, columns)
    dossiers = Dossier.includes(:corrections, :pending_corrections).find(dossier_ids)

    # each project should return
    # { dossier_id => { column_id => value, column_id2 ... }, dossier_id2 ... }
    projection = columns.group_by(&:projector)
      .map { |p, columns| p.project(columns, dossiers) }
      .reduce(:deep_merge)

    dossiers.map do |dossier|
      DossierProjection.new(
        dossier,
        columns.map { |column| projection[dossier.id][column.id] }
      )
    end
  end
end
