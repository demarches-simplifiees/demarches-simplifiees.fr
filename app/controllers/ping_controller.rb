class PingController < ApplicationController
  def index
    Rails.logger.silence do
      if (ActiveRecord::Base.connected?)
        head :ok
      else
        head :internal_server_error
      end
    end
  end
end
