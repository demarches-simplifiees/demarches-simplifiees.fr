class Admin::ProceduresController < AdminController
  def archive
    procedure = current_administrateur.procedures.find(params[:procedure_id])
    procedure.close!

    flash.notice = "Démarche close"
    redirect_to admin_procedures_path

  rescue ActiveRecord::RecordNotFound
    flash.alert = 'Démarche inexistante'
    redirect_to admin_procedures_path
  end
end
