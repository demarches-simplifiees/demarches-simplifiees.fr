# frozen_string_literal: true

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

  API_URL = 'https://www.data.gouv.fr/api/1'

  class << self
    def existing_file_url(dataset, resource)
      response = Typhoeus.get(
        datagouv_resource_url(dataset, resource),
        followlocation: true
      )

      return nil unless response.success?

      JSON.parse(response.body)["url"]
    end

    def upload(io, dataset, resource = nil)
      response = Typhoeus.post(
        datagouv_upload_url(dataset, resource),
        body: {
          file: io
        },
        headers: { "X-Api-Key" => datagouv_secret[:api_key] }
      )
      io.close

      if response.success?
        response.body
      else
        raise RequestFailed.new(datagouv_upload_url(dataset, resource), response)
      end
    end

    def upload_csv(file_name, csv, dataset, resource)
      Tempfile.create([file_name, '.csv']) do |file|
        file << csv.to_csv
        file.rewind

        response = Typhoeus.post(
          datagouv_upload_url(dataset, resource),
          body: {
            file: file
          },
          headers: { "X-Api-Key" => datagouv_secret[:api_key] }
        )

        if response.success?
          response.body
        else
          raise RequestFailed.new(datagouv_upload_url(dataset, resource), response)
        end
      end
    end

    private

    def datagouv_resource_url(dataset, resource)
      [
        API_URL,
        "/datasets/", dataset,
        "/resources/", resource
      ].join
    end

    def datagouv_upload_url(dataset, resource = nil)
      if resource.present?
        [
          API_URL,
          "/datasets/", dataset,
          "/resources/", resource,
          "/upload/"
        ].join
      else
        [
          API_URL,
          "/datasets/", dataset,
          "/upload/"
        ].join
      end
    end

    def datagouv_secret
      Rails.application.secrets.datagouv
    end
  end
end
