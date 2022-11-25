class BatchOperationProcessOneJob < ApplicationJob
  retry_on StandardError, attempts: 1

  def perform(batch_operation, dossier)
    dossier = batch_operation.dossiers_safe_scope.find(dossier.id)
    begin
      batch_operation.process_one(dossier)
      batch_operation.track_processed_dossier(true, dossier)
    rescue => error
      batch_operation.track_processed_dossier(false, dossier)
      raise error
    end
  rescue ActiveRecord::RecordNotFound
    dossier.update(batch_operation_id: nil)
  end
end
