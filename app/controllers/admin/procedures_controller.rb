class Admin::ProceduresController < AdminController

  def index
    @procedures = current_administrateur.procedures.where(archived: false)
    @procedures = @procedures.paginate(:page => params[:page], :per_page => 12)
  end

  def archived
    @procedures_archived = current_administrateur.procedures.where(archived: true)
    @procedures_archived = @procedures_archived.paginate(:page => params[:page], :per_page => 12)
  end

  def show
    @procedure = current_administrateur.procedures.find(params[:id])
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
    redirect_to admin_procedure_types_de_champ_path(procedure_id: @procedure.id)
  end

  def update

    @procedure = current_administrateur.procedures.find(params[:id])

    unless @procedure.update_attributes(create_procedure_params)
      flash.now.alert = @procedure.errors.full_messages.join('<br />').html_safe
      return render 'show'
    end
    flash.notice = 'Préocédure modifiée'
    redirect_to admin_procedures_path
  end

  def archive
    @procedure = current_administrateur.procedures.find(params[:procedure_id])
    @procedure.update_attributes({archived: true})

    flash.notice = 'Procédure archivée'
    redirect_to admin_procedures_path

  rescue ActiveRecord::RecordNotFound
    flash.alert = 'Procédure inéxistante'
    redirect_to admin_procedures_path
  end

  private

  def create_procedure_params
    params.require(:procedure).permit(:libelle, :description, :organisation, :direction, :lien_demarche, :use_api_carto).merge(administrateur_id: current_administrateur.id)
  end
end
