# frozen_string_literal: true

class ActiveStorage::VirusScanner
  def initialize(blob)
    @blob = blob
  end

  attr_reader :blob

  PENDING = 'pending'
  INFECTED = 'infected'
  SAFE = 'safe'
  INTEGRITY_ERROR = 'integrity_error'

  def pending?
    virus_scan_result == PENDING
  end

  def infected?
    virus_scan_result == INFECTED
  end

  def safe?
    virus_scan_result == SAFE
  end

  def corrupt?
    virus_scan_result == INTEGRITY_ERROR
  end

  def done?
    started? && virus_scan_result != PENDING
  end

  def started?
    virus_scan_result.present?
  end

  def attributes
    blob.open do |file|
      if ClamavService.safe_file?(file.path)
        { virus_scan_result: SAFE, virus_scanned_at: Time.zone.now }
      else
        { virus_scan_result: INFECTED, virus_scanned_at: Time.zone.now }
      end
    end
  end

  private

  def virus_scan_result
    blob.virus_scan_result || blob.metadata[:virus_scan_result]
  end
end
