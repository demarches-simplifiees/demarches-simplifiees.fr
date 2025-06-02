# frozen_string_literal: true

class Champs::RepetitionController < Champs::ChampController
  def add
    row = @champ.add_row(@champ.dossier.revision)
    @first_champ_id = row.map(&:focusable_input_id).compact.first
    @row_id = row.first&.row_id
    @row_number = @row_id.nil? ? 0 : @champ.row_ids.find_index(@row_id) + 1
  end

  def remove
    @champ.remove_row(params[:row_id])
    @to_remove = "safe-row-selector-#{params[:row_id]}"
    @to_focus = @champ.focusable_input_id || helpers.dom_id(@champ, :create_repetition)
  end

  private

  def params_row_id
    nil
  end
end
