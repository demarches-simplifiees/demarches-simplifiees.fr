class ClamavService
  def self.safe_io_data? path_file
    client = ClamAV::Client.new

    response = client.execute(ClamAV::Commands::ScanCommand.new(path_file))

    puts response
  end
end