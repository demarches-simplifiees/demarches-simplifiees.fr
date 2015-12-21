class AdminController < ApplicationController
  before_action :authenticate_administrateur!

  def index
    redirect_to (admin_procedures_path)
  end

  def retrieve_procedure
    id = params[:procedure_id] || params[:id ]

    @procedure = current_administrateur.procedures.find(id)

    unless @procedure.dossiers.count == 0
      render json: {message: 'Procedure locked'}, status: 403
    end

  rescue ActiveRecord::RecordNotFound
    render json: {message: 'Procedure not found'}, status: 404
  end
end
