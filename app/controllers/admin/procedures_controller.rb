class Admin::ProceduresController < AdminController

  def index
    @procedures = current_administrateur.procedures
    @procedures = @procedures.paginate(:page => params[:page], :per_page => 2)
  end

  def show
    @procedure = Procedure.find(params[:id])
    @types_de_champ = @procedure.types_de_champ.order(:order_place)
    @types_de_piece_justificative = @procedure.types_de_piece_justificative.order(:libelle)

  rescue ActiveRecord::RecordNotFound
    flash.alert = 'Procédure inéxistante'
    redirect_to admin_procedures_path
  end

  def new
    @procedure ||= Procedure.new
  end

  def create
    @procedure = Procedure.new(create_procedure_params)

    unless @procedure.save
      flash.now.alert = @procedure.errors.full_messages.join('<br />').html_safe
      return render 'new'
    end

    flash.notice = 'Procédure enregistrée'
    redirect_to admin_procedure_types_de_champ_path(procedure_id:  @procedure.id)
  end

  def update

    @procedure = Procedure.find(params[:id])

    unless @procedure.update_attributes(create_procedure_params)
      flash.now.alert = @procedure.errors.full_messages.join('<br />').html_safe
      return render 'show'
    end
    flash.notice = 'Préocédure modifiée'
    redirect_to admin_procedures_path
  end

  private

  def create_procedure_params
    params.require(:procedure).permit(:libelle, :description, :organisation, :direction, :lien_demarche, :use_api_carto).merge(administrateur_id: current_administrateur.id)
  end
end
