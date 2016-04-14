class ClamavService
  def self.safe_io_data? io_data
    client = ClamAV::Client.new

    io = StringIO.new(io_data)

    response = client.execute(ClamAV::Commands::InstreamCommand.new(io))

    puts response

  end
end