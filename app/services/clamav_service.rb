class ClamavService
  def self.safe_file?(file_path)
    if Rails.env.development?
      Rails.logger.info("Rails.env = development => fake scan") # FIXME : remove me
      return true
    end

    FileUtils.chmod(0666, file_path)

    client = ClamAV::Client.new
    response = client.execute(ClamAV::Commands::ScanCommand.new(file_path))
    Rails.logger.info("ClamAV response for #{file_path} : #{response.first.class.name}") # FIXME : remove me
    response.first.class != ClamAV::VirusResponse
  end
end
