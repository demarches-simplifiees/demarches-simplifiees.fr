class Users::RecapitulatifController < UsersController
  def show
    @dossier = Dossier.find(params[:dossier_id])
    @dossier = @dossier.decorate
    @procedure = @dossier.procedure

    # mettre dans le modele
    @commentaires = @dossier.commentaires.order(created_at: :desc)

    @commentaires = @commentaires.all.decorate

    #TODO load user email
    @commentaire_email = 'user@email'
  rescue ActiveRecord::RecordNotFound
    flash.alert = t('errors.messages.dossier_not_found')
    redirect_to url_for(controller: :siret)
  end

  def propose
    show

    @dossier.next_step! 'user', 'propose'
    flash.notice = 'Dossier soumis avec succès.'

    render 'show'
  end

  def depose
    show

    @dossier.next_step! 'user', 'depose'
    flash.notice = 'Dossier déposé avec succès.'

    render 'show'
  end
end
