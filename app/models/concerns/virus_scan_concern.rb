module VirusScanConcern
  extend ActiveSupport::Concern

  attr_reader :attachment_attribute

  def add_virus_scan_on(piece_justificative)
    @attachment_attribute = piece_justificative
  end

  def virus_scan
    VirusScan.find_by(blob_key: self.attachment_attribute.blob.key)
  end

  def create_virus_scan(piece_justificative)
    if piece_justificative&.attachment&.blob.present?
      VirusScan.find_or_create_by!(blob_key: piece_justificative.blob.key) do |virus_scan|
        virus_scan.status = VirusScan.statuses.fetch(:pending)
      end
    end
  end
end
