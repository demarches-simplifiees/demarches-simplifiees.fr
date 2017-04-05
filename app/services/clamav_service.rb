class ClamavService
  def self.safe_file? path_file

    if Rails.env == 'development'
      return CLAMAV[:response] if CLAMAV[:mock?]
    end

    FileUtils.chmod 0666, path_file

    client = ClamAV::Client.new
    response = client.execute(ClamAV::Commands::ScanCommand.new(path_file))

    return false if response.first.class == ClamAV::VirusResponse
    true
  end
end
