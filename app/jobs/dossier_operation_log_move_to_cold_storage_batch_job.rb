class DossierOperationLogMoveToColdStorageBatchJob < ApplicationJob
  queue_as :low_priority_sub_second_batch

  def perform(ids)
    DossierOperationLog.where(id: ids)
      .with_data
      .find_each(&:move_to_cold_storage!)
  end
end
