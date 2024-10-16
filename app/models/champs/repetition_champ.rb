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

  def focusable_input_id
    rows.last&.first&.focusable_input_id
  end

  def blank?
    row_ids.empty?
  end

  def search_terms
    # The user cannot enter any information here so it doesn’t make much sense to search
  end

  def rows_for_export
    row_ids.map.with_index(1) do |row_id, index|
      Champs::RepetitionChamp::Row.new(index:, row_id:, dossier:)
    end
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

    def spreadsheet_columns(types_de_champ)
      [
        ['Dossier ID', :dossier_id],
        ['Ligne', :index]
      ] + dossier.champs_for_export(types_de_champ, row_id)
    end
  end
end
