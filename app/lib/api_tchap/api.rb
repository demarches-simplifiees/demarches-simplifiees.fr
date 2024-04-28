# frozen_string_literal: true

class APITchap::API
  class ResourceNotFound < StandardError
  end

  def self.get_hs(email)
    call([API_TCHAP_URL, "info?medium=email&address=#{email}"].join('/'))
  end

  private

  def self.call(url)
    response = Typhoeus.get(url)

    if response.success?
      response.body
    else
      message = response.code == 0 ? response.return_message : response.code.to_s
      Rails.logger.error "[APITchap] Error on #{url}: #{message}"
      raise ResourceNotFound
    end
  end
end
