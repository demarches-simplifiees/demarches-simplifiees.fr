class AdminController < ApplicationController
  before_action :authenticate_administrateur!

  def index
    redirect_to (admin_procedures_path)
  end

  def retrieve_procedure
    id = params[:procedure_id] || params[:id]

    @procedure = current_administrateur.procedures.find(id)

  rescue ActiveRecord::RecordNotFound
    flash.alert = 'Procédure inéxistante'
    redirect_to admin_procedures_path, status: 404
  end

  def procedure_locked?
    if @procedure.locked?
      flash.alert = 'Procédure verrouillée'
      redirect_to admin_procedure_path(id: @procedure.id)
    end
  end
end
