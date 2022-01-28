class ClamavService
  def self.safe_file?(file_path)
    return true if !Rails.configuration.x.clamav.enabled

    FileUtils.chmod(0666, file_path)

    client = ClamAV::Client.new
    response = client.execute(ClamAV::Commands::ScanCommand.new(file_path)).first

    case response
    when ClamAV::SuccessResponse
      true
    when ClamAV::VirusResponse
      false
    when ClamAV::ErrorResponse
      raise "ClamAV ErrorResponse : #{response.error_str}"
    else
      raise "ClamAV unkown response #{response.class.name}"
    end
  end
end
