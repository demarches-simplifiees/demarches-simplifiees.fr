class Users::DossiersController < ApplicationController
  before_action :authenticate_user!
  def index
    @dossiers = Dossier.all.decorate
  end
end
