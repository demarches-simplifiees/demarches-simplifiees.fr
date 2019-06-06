class Universign::API
  ## Universign Timestamp POST API
  # Official documentation is at https://help.universign.com/hc/fr/articles/360000898965-Guide-d-intégration-horodatage

  def self.ensure_properly_configured!
    if userpwd.blank?
      raise StandardError, 'Universign API is not properly configured'
    end
  end

  def self.timestamp(data)
    ensure_properly_configured!

    response = Typhoeus.post(
      UNIVERSIGN_API_URL,
      userpwd: userpwd,
      body: body(data)
    )

    if response.success?
      response.body
    else
      raise StandardError, "Universign timestamp query failed: #{response.status_message}"
    end
  end

  private

  def self.body(data)
    {
      'hashAlgo': 'SHA256',
      'withCert': 'true',
      'hashValue': data
    }
  end

  def self.userpwd
    Rails.application.secrets.universign[:userpwd]
  end
end
