class PingController < ApplicationController

  def index
    if (ActiveRecord::Base.connected?)
      render nothing: true, status: 200, content_type: "application/json"
    else
      render nothing: true, status: 500, content_type: "application/json"
    end
  end

end
