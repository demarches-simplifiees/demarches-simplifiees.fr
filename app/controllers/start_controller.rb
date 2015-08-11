class StartController < ApplicationController
  def index

  end

  def error_siret
    flash.now.alert = 'Ce SIRET n\'est pas valide'
    render 'index'
  end

  def error_login
    flash.now.alert = 'Ce compte n\'existe pas'
    render 'index'
  end

  def error_dossier
    flash.now.alert = 'Ce dossier n\'existe pas'
    render 'index'
  end
end
