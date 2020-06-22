class PingController < ApplicationController
  def index
    Rails.logger.silence do
      status_code = if File.file?(Rails.root.join("maintenance"))
        # See https://cbonte.github.io/haproxy-dconv/2.0/configuration.html#4.2-http-check%20disable-on-404
        :not_found
      elsif (ActiveRecord::Base.connected?)
        :ok
      else
        :internal_server_error
      end

      head status_code, content_type: "application/json"
    end
  end
end
