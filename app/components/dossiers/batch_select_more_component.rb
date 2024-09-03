# frozen_string_literal: true

class Dossiers::BatchSelectMoreComponent < ApplicationComponent
  def initialize(dossiers_count:, filtered_sorted_ids:)
    @dossiers_count = dossiers_count
    @filtered_sorted_ids = filtered_sorted_ids
  end

  def not_selected_button_data
    {
      action: "batch-operation#onSelectMore",
      dossiers: @filtered_sorted_ids.first(Instructeurs::ProceduresController::BATCH_SELECTION_LIMIT).join(',')
    }
  end

  def selected_button_data
    {
      action: "batch-operation#onDeleteSelection"
    }
  end

  def not_selected_text
    if @dossiers_count <= Instructeurs::ProceduresController::BATCH_SELECTION_LIMIT
      t(".select_all", dossiers_count: @dossiers_count)
    else
      t(".select_all_limit", dossiers_count: @dossiers_count, limit: Instructeurs::ProceduresController::BATCH_SELECTION_LIMIT)
    end
  end

  def selected_text
    if @dossiers_count <= Instructeurs::ProceduresController::BATCH_SELECTION_LIMIT
      t(".selected_all", dossiers_count: @dossiers_count)
    else
      t(".selected_all_limit", limit: Instructeurs::ProceduresController::BATCH_SELECTION_LIMIT)
    end
  end
end
