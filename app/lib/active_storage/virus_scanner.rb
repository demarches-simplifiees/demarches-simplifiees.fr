class ActiveStorage::VirusScanner
  include ActiveStorage::Downloading

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
    blob.metadata[:scanned_at].present?
  end

  def started?
    blob.metadata[:virus_scan_result].present?
  end

  def analyze_later
    if !done?
      blob.update!(metadata: blob.metadata.merge(virus_scan_result: PENDING))
      VirusScannerJob.perform_later(blob)
    end
  end

  def metadata
    begin
      download_blob_to_tempfile do |file|
        if ClamavService.safe_file?(file.path)
          { virus_scan_result: SAFE, scanned_at: Time.zone.now }
        else
          { virus_scan_result: INFECTED, scanned_at: Time.zone.now }
        end
      end
    rescue StandardError => e
      Raven.capture_exception(e)
    end
  end
end
