# frozen_string_literal: true

# Run a virus scan on all attachments after they are analyzed.
#
# We're using a class extension to ensure that all attachments get scanned,
# regardless on how they were created. This could be an ActiveStorage::Analyzer,
# but as of Rails 6.1 only the first matching analyzer is ever run on
# a blob (and we may want to analyze the dimension of a picture as well
# as scanning it).
module AttachmentVirusScannerConcern
  extend ActiveSupport::Concern

  included do
    after_create_commit :scan_for_virus_later
  end

  private

  def scan_for_virus_later
    return if blob.nil?

    # do not scan if the blob is already marked as safe
    # usually because of metadata[:virus_scan_result] = ActiveStorage::VirusScanner::SAFE
    # added on a blob built by the application itself
    return if blob.virus_scan_result == ActiveStorage::VirusScanner::SAFE

    blob.scan_for_virus_later
  end
end
