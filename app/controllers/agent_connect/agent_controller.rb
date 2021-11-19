class AgentConnect::AgentController < ApplicationController
  def index
  end

  def login
    redirect_to AgentConnectService.authorization_uri
  end
end
