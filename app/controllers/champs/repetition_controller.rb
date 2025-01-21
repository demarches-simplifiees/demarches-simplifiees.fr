# frozen_string_literal: true

class Champs::RepetitionController < Champs::ChampController
  def add
    @row_id = @champ.add_row(updated_by: current_user.email)
    @first_champ_id = @champ.focusable_input_id
    @row_number = @row_id.nil? ? 0 : @champ.row_ids.find_index(@row_id) + 1
    @champ.dossier.touch_champs_changed([:last_champ_updated_at])
  end

  def remove
    @champ.remove_row(params[:row_id], updated_by: current_user.email)
    @to_remove = "safe-row-selector-#{params[:row_id]}"
    @to_focus = @champ.focusable_input_id || helpers.dom_id(@champ, :create_repetition)
    @champ.dossier.touch_champs_changed([:last_champ_updated_at])
  end

  private

  def params_row_id
    nil
  end
end
