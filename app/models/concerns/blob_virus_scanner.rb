# TODO: once we're using Rails 6, use the hooks on attachments creation
# (rather than on blob creation).
# This will help to avoid cloberring metadata accidentally (as metadata
# are more stable on attachment creation than on blob creation).
module BlobVirusScanner
  extend ActiveSupport::Concern

  included do
    before_create :set_pending
    after_update_commit :enqueue_virus_scan
  end

  def virus_scanner
    ActiveStorage::VirusScanner.new(self)
  end

  private

  def set_pending
    self.metadata[:virus_scan_result] ||= ActiveStorage::VirusScanner::PENDING
  end

  def enqueue_virus_scan
    if analyzed? && !virus_scanner.done?
      VirusScannerJob.perform_later(self)
    end
  end
end
