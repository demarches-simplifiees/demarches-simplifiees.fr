class Admin::ChangeDossierStateController < AdminController
  def index
    @dossier = Dossier.new
  end

  def change
    @dossier = Dossier.find(params[:dossier][:id])
    @dossier.update state: params[:next_state]
  end

  def check
    @dossier = Dossier.find(params[:dossier][:id])

    if @dossier.procedure.administrateur.email != current_administrateur.email
      flash.alert = 'Dossier introuvable'
      return redirect_to admin_change_dossier_state_path
    end
  end
end
