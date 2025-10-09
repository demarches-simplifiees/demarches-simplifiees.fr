# frozen_string_literal: true

class EditableChamp::RepetitionRowComponent < ApplicationComponent
  attr_reader :row_id, :row_number

  def initialize(row_number:, row: nil, seen_at: nil)
    @row = row
    @dossier = row.dossier
    @row_id = row.row_id
  end
end
