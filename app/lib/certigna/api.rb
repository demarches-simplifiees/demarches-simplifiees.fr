# frozen_string_literal: true

class Certigna::API
  ## Certigna Timestamp POST API
  # the CAfile used to controle the timestamp token is build:
  # curl http://autorite.certigna.fr/ACcertigna.crt http://autorite.certigna.fr/entityca.crt > authorities.crt

  def self.ensure_properly_configured!
    if userpwd.blank?
      raise StandardError, 'Certigna API is not properly configured'
    end
  end

  def self.enabled?
    ENV.fetch("CERTIGNA_ENABLED", "enabled") == "enabled"
  end

  def self.timestamp(data)
    ensure_properly_configured!

    response = Typhoeus.post(
      CERTIGNA_API_URL,
      userpwd: userpwd,
      body: body(data)
    )

    if response.success?
      response.body
    else
      raise StandardError, "Certigna timestamp query failed: #{response.status_message}"
    end
  end

  private

  def self.body(data)
    {
      'hashAlgorithm': 'SHA256',
      'certReq': 'true',
      'hashedMessage': data
    }
  end

  def self.userpwd
    ENV["CERTIGNA_USERPWD"]
  end
end
