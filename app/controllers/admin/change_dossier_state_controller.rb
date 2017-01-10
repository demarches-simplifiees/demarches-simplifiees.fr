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
  end
end