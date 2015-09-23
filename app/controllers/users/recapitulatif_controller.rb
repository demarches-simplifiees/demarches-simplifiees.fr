class Users::RecapitulatifController < UsersController
  def show

    @dossier = Dossier.find(params[:dossier_id])
    @dossier = @dossier.decorate

    # mettre dans le modele
    @commentaires = @dossier.commentaires.order(created_at: :desc)

    @commentaires = @commentaires.all.decorate

    #TODO load user email
    @commentaire_email = 'user@email'
  rescue ActiveRecord::RecordNotFound
    flash.alert = t('errors.messages.dossier_not_found')
    redirect_to url_for(controller: :siret)
  end
end
