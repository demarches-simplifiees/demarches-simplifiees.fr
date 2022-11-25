class BatchOperationProcessOneJob < ApplicationJob
  # what about wrapping all of that in a transaction
  # but, what about nested transaction because batch_operation.process_one(dossier) can run transaction
  def perform(batch_operation, dossier)
    success = true
    begin
      batch_operation.process_one(dossier)
    rescue => error
      success = false
      raise error
    ensure
      batch_operation.track_dossier_processed(success, dossier)
    end
  end
end
