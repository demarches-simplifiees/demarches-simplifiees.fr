class ClamavService
  def self.safe_file? file_path
    if Rails.env == 'development'
      return CLAMAV[:response] if CLAMAV[:mock?]
    end

    FileUtils.chmod 0666, file_path

    client = ClamAV::Client.new
    response = client.execute(ClamAV::Commands::ScanCommand.new(file_path))

    return false if response.first.class == ClamAV::VirusResponse
    true
  end
end
