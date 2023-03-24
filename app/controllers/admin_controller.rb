class AdminController < ApplicationController
  before_action :authenticate_administrateur!

  def index
    redirect_to(admin_procedures_path)
  end

  def retrieve_procedure
    id = params[:procedure_id] || params[:id]

    @procedure = current_administrateur.procedures.find(id)

  rescue ActiveRecord::RecordNotFound
    flash.alert = 'Démarche inexistante'
    redirect_to admin_procedures_path, status: 404
  end

  def reset_procedure
    if @procedure.brouillon?
      @procedure.reset!
    end
  end
end
