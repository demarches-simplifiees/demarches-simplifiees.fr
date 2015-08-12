module DossierConcern

  def current_dossier
    Dossier.find(params[:dossier_id])
  end

end