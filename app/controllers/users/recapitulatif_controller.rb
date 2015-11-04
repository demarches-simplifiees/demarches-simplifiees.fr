class Users::RecapitulatifController < UsersController
  def show
    @dossier = current_user_dossier
    @dossier = @dossier.decorate
    @procedure = @dossier.procedure
    @champs = @dossier.ordered_champs

    @commentaires = @dossier.ordered_commentaires
    @commentaires = @commentaires.all.decorate

    @commentaire_email = current_user.email
  rescue ActiveRecord::RecordNotFound
    flash.alert = t('errors.messages.dossier_not_found')
    redirect_to url_for(root_path)
  end

  def initiate
    show

    @dossier.next_step! 'user', 'initiate'
    flash.notice = 'Dossier soumis avec succès.'

    render 'show'
  end

  def submit
    show

    @dossier.next_step! 'user', 'submit'
    flash.notice = 'Dossier déposé avec succès.'

    render 'show'
  end
end
