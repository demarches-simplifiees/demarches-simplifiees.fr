# frozen_string_literal: true

class PingController < ApplicationController
  def index
    Rails.logger.silence do
      status_code = if Rails.root.join("maintenance").file?
        # See https://cbonte.github.io/haproxy-dconv/2.0/configuration.html#4.2-http-check%20disable-on-404
        :not_found
      elsif (ActiveRecord::Base.connection.execute('select 1 as test;').first['test'] == 1)
        :ok
      else
        :internal_server_error
      end

      head status_code, content_type: "application/json"
    end
  end
end
