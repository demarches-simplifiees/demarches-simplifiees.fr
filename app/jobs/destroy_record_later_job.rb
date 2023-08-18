class DestroyRecordLaterJob < ApplicationJob
  discard_on ActiveRecord::RecordNotFound

  def perform(record)
    record.destroy
  end
end
