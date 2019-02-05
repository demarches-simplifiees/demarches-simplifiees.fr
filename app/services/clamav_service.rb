class ClamavService
  def self.safe_file?(file_path)
    if Rails.env.development?
      return true
    end

    FileUtils.chmod(0666, file_path)

    client = ClamAV::Client.new
    response = client.execute(ClamAV::Commands::ScanCommand.new(file_path)).first
    if response.class == ClamAV::SuccessResponse
      true
    elsif response.class == ClamAV::VirusResponse
      false
    elsif response.class == ClamAV::ErrorResponse
      raise "ClamAV ErrorResponse : #{response.error_str}"
    else
      raise "ClamAV unkown response #{response.class.name}"
    end
  end
end
