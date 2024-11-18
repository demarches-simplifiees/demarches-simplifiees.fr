# frozen_string_literal: true

class Tableau
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

  attr_accessor :data

  def initialize(dossiers, columns, corrections_by_dossier_id)
    @dossiers = dossiers
    @columns = columns
    @corrections_by_dossier_id = corrections_by_dossier_id
    @data = {}
  end

  def add_data(data)
    @data.deep_merge!(data)
  end

  def projected_dossiers
    @dossiers.map do |dossier|
      DossierProjection.new(
        dossier,
        @corrections_by_dossier_id[dossier.id],
        @columns.map { |column| @data[dossier.id][column.id] }
      )
    end
  end
end
