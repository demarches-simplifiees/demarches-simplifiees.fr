# Run a virus scan on all blobs after they are analyzed.
#
# We're using a class extension to ensure that all blobs get scanned,
# regardless on how they were created. This could be an ActiveStorage::Analyzer,
# but as of Rails 6.1 only the first matching analyzer is ever run on
# a blob (and we may want to analyze the dimension of a picture as well
# as scanning it).
#
# The `after_commit` hook is triggered, among other cases, when
# the analyzer updates the blob metadata. When the analyzer has run,
# it is now safe to start our own scanning, without risking to have
# two concurrent jobs overwriting the metadata of the blob.
module BlobVirusScannerConcern
  extend ActiveSupport::Concern

  included do
    before_create :set_pending
    after_commit :enqueue_virus_scan
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
