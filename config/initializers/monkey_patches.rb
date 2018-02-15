# Monkey patch ActiveStorage to make Range query compatible with CleverCloud Cellar
#
# FIXME : remove when better fix is available
ActiveStorage::Identification.class_eval do
  private

  def identifiable_chunk
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |client|
      client.get(uri, "Range" => "bytes=0-4096").body
    end
  end
end
