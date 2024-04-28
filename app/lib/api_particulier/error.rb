# frozen_string_literal: true

module APIParticulier
  module Error
    class HttpError < ::StandardError
      def initialize(response)
        connect_time = response.connect_time
        curl_message = response.return_message
        http_error_code = response.code
        datetime = response.headers.fetch('Date', DateTime.current.inspect)
        total_time = response.total_time

        uri = URI.parse(response.effective_url)
        url = "#{uri.host}#{uri.path}"

        msg = <<~TEXT
          url: #{url}
          HTTP error code: #{http_error_code}
          #{response.body.force_encoding('UTF-8')}
          curl message: #{curl_message}
          total time: #{total_time}
          connect time: #{connect_time}
          datetime: #{datetime}
        TEXT

        super(msg)
      end
    end

    class RequestFailed < HttpError; end

    class Unauthorized < HttpError; end
  end
end
