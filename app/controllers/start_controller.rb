class StartController < ApplicationController
  def index
    get_procedure_infos

    if @procedure.nil?
      error_procedure
    end
  rescue ActiveRecord::RecordNotFound
    error_procedure
  end

  def error_procedure
    render :file => "#{Rails.root}/public/404_procedure_not_found.html",  :status => 404
  end

  def error_siret
    get_procedure_infos
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

  private

  def get_procedure_infos
    @procedure = Procedure.find(params['procedure_id'])
  end
end
