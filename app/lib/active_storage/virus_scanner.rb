class ActiveStorage::VirusScanner
  def initialize(blob)
    @blob = blob
  end

  attr_reader :blob

  PENDING = 'pending'
  INFECTED = 'infected'
  SAFE = 'safe'

  def pending?
    blob.metadata[:virus_scan_result] == PENDING
  end

  def infected?
    blob.metadata[:virus_scan_result] == INFECTED
  end

  def safe?
    blob.metadata[:virus_scan_result] == SAFE
  end

  def done?
    started? && blob.metadata[:virus_scan_result] != PENDING
  end

  def started?
    blob.metadata[:virus_scan_result].present?
  end

  def metadata
    blob.open do |file|
      if ClamavService.safe_file?(file.path)
        { virus_scan_result: SAFE, scanned_at: Time.zone.now }
      else
        { virus_scan_result: INFECTED, scanned_at: Time.zone.now }
      end
    end
  end
end
