# frozen_string_literal: true

class DossierOperationLogMoveToColdStorageBatchJob < ApplicationJob
  queue_as :low

  def perform(ids)
    DossierOperationLog.where(id: ids)
      .with_data
      .find_each(&:move_to_cold_storage!)
  end
end
