# frozen_string_literal: true

class Champs::RepetitionChamp < Champ
  delegate :libelle_for_export, to: :type_de_champ

  def rows
    dossier.project_rows_for(type_de_champ)
  end

  def row_ids
    dossier.repetition_row_ids(type_de_champ)
  end

  def add_row(updated_by:)
    dossier.repetition_add_row(type_de_champ, updated_by:)
  end

  def remove_row(row_id, updated_by:)
    dossier.repetition_remove_row(type_de_champ, row_id, updated_by:)
  end

  def focusable_input_id(attribute = :value)
    rows.last&.first&.focusable_input_id(attribute)
  end

  def discarded?
    discarded_at.present?
  end

  def discard!
    touch(:discarded_at)
  end

  def search_terms
    # The user cannot enter any information here so it doesn’t make much sense to search
  end

  class Row < Hashie::Dash
    property :index
    property :row_id
    property :dossier

    def dossier_id
      dossier.id.to_s
    end

    def read_attribute_for_serialization(attribute)
      self[attribute]
    end

    def spreadsheet_columns(types_de_champ, export_template: nil, format:)
      [
        ['Dossier ID', :dossier_id],
        ['Ligne', :index]
      ] + dossier.champ_values_for_export(types_de_champ, row_id:, export_template:, format:)
    end
  end
end
