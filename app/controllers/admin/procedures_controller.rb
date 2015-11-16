class Admin::ProceduresController < AdminController

  def index
    @procedures = current_administrateur.procedures
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

    process_new_types_de_champ_params
    process_new_types_de_piece_justificative_params

    flash.notice = 'Procédure enregistrée'
    redirect_to admin_procedures_path
  end

  def update

    @procedure = Procedure.find(params[:id])

    unless @procedure.update_attributes(create_procedure_params)
      flash.now.alert = @procedure.errors.full_messages.join('<br />').html_safe
      return render 'show'
    end

    process_new_types_de_champ_params
    process_update_types_de_champ_params

    process_new_types_de_piece_justificative_params
    process_update_types_de_piece_justificative_params

    flash.notice = 'Préocédure modifiée'
    redirect_to admin_procedures_path
  end

  private

  def create_procedure_params
    params.require(:procedure).permit(:libelle, :description, :organisation, :direction, :lien_demarche, :use_api_carto)
  end
end
