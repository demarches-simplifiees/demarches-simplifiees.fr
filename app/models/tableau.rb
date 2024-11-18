# frozen_string_literal: true

class Tableau
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

  attr_accessor :dossiers, :data

  def initialize(dossier_ids, columns)
    @dossiers_ids = dossier_ids
    @columns = columns
    @data = {}
  end

  def add_data(data)
    @data.deep_merge!(data)
  end

  def projected_dossiers
    @dossiers_ids.map do |dossier_id|
      DossierProjection.new(
        @dossiers.find { _1.id == dossier_id },
        dossier_id,
        nil,
        nil,
        nil,
        @columns.map { |column| @data[dossier_id][column.id] }
      )
    end
  end
end
