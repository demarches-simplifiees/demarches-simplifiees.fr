class CleanupStaleExportsJob < ApplicationJob
  queue_as :cron

  def perform(*args)
    ActiveStorage::Attachment.where(
      "name in ('csv_export_file', 'ods_export_file', 'xlsx_export_file') and created_at < ?",
      Procedure::MAX_DUREE_CONSERVATION_EXPORT.ago
    ).find_each(&:purge_later)
  end
end
