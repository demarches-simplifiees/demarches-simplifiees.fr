class CleanupStaleExportsJob < ApplicationJob
  queue_as :cron

  def perform(*args)
    attachments = ActiveStorage::Attachment.where(
      "name in ('csv_export_file', 'ods_export_file', 'xlsx_export_file') and created_at < ?",
      Procedure::MAX_DUREE_CONSERVATION_EXPORT.ago
    )
    attachments.each do |attachment|
      procedure = Procedure.find(attachment.record_id)
      # export can't be queued if it's already attached
      #  so we clean the flag up just in case it was not removed during
      # the asynchronous generation
      case attachment.name
      when 'csv_export_file'
        procedure.update(csv_export_queued: false)
      when 'ods_export_file'
        procedure.update(ods_export_queued: false)
      when 'xlsx_export_file'
        procedure.update(xlsx_export_queued: false)
      end
      # and we remove the stale attachment
      attachment.purge_later
    end
  end
end
