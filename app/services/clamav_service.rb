class ClamavService
  def self.safe_file?(file_path)
    if Rails.env.development?
      return true
    end

    FileUtils.chmod(0666, file_path)

    client = ClamAV::Client.new
    response = client.execute(ClamAV::Commands::ScanCommand.new(file_path))

    if response.first.class == ClamAV::VirusResponse
      return false
    end

    true
  end
end
