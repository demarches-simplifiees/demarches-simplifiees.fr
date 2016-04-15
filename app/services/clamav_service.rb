class ClamavService
  def self.safe_file? path_file

    FileUtils.chmod 0666, path_file

    client = ClamAV::Client.new
    response = client.execute(ClamAV::Commands::ScanCommand.new(path_file))

    return false if response.first.class == ClamAV::VirusResponse
    true
  end
end