class APIDatagouv::API
  class RequestFailed < StandardError
    def initialize(url, response)
      msg = <<-TEXT
        HTTP error code: #{response.code}
        #{response.body}
      TEXT

      super(msg)
    end
  end

  class << self
    def upload(path)
      io = File.new(path, 'r')
      response = Typhoeus.post(
        datagouv_upload_url,
        body: {
          file: io
        },
        headers: { "X-Api-Key" => datagouv_secret[:api_key] }
      )
      io.close

      if response.success?
        response.body
      else
        raise RequestFailed.new(datagouv_upload_url, response)
      end
    end

    private

    def datagouv_upload_url
      [
        datagouv_secret[:api_url],
        "/datasets/", datagouv_secret[:ds_demarches_publiques_dataset],
        "/resources/", datagouv_secret[:ds_demarches_publiques_resource],
        "/upload/"
      ].join
    end

    def datagouv_secret
      Rails.application.secrets.datagouv
    end
  end
end
