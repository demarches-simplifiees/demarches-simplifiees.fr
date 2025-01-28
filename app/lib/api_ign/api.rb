# frozen_string_literal: true

class APIIgn::API
  include Dry::Monads[:result]

  def self.fetch_parcelle(id:)
    uri = URI("https://data.geopf.fr/geocodage/search")
    uri.query = URI.encode_www_form({ q: id, index: 'parcel', returntruegeometry: "1" })

    result = API::Client.new.(url: uri.to_s)

    case result
    in Success(body:)
      body.dig(:features, 0, :properties, :truegeometry)
    else
      raise ArgumentError, "Lookup error: #{result.inspect}"
    end
  end
end
