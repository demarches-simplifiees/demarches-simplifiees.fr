class BatchOperationProcessOneJob < ApplicationJob
  # what about wrapping all of that in a transaction
  # but, what about nested transaction because batch_operation.process_one(dossier) can run transaction
  def perform(batch_operation, dossier)
    success = true
    begin
      batch_operation.process_one(dossier)
      dossier.update(batch_operation: nil)
    rescue => error
      success = false
      raise error
    ensure
      batch_operation.reload # reload before deciding if it has been finished
      batch_operation.run_at = Time.zone.now if batch_operation.called_for_first_time?
      batch_operation.finished_at = Time.zone.now if batch_operation.called_for_last_time?
      if success # beware to this one, will be refactored for stronger atomicity
        batch_operation.success_dossier_ids.push(dossier.id)
        batch_operation.failed_dossier_ids = batch_operation.failed_dossier_ids.reject { |d| d.dossier.id }
      else
        batch_operation.failed_dossier_ids.push(dossier.id)
      end
      batch_operation.save!
    end
  end
end
