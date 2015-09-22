class StartController < ApplicationController
  def index
    @procedure_id = params['procedure_id']
    @procedure = Procedure.find(@procedure_id)

    if @procedure.nil?
      error_procedure
    end
  rescue ActiveRecord::RecordNotFound
    error_procedure
  end

  def error_procedure
    render :file => "#{Rails.root}/public/404.html",  :status => 404
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
