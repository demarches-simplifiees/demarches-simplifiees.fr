class PingController < ApplicationController
  def index
    Rails.logger.silence do
      if (ActiveRecord::Base.connected?)
        head :ok, content_type: "application/json"
      else
        head :internal_server_error, content_type: "application/json"
      end
    end
  end
end
