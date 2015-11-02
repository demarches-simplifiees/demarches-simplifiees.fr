class Users::RecapitulatifController < UsersController
  def show
    @dossier = current_user_dossier
    @dossier = @dossier.decorate
    @procedure = @dossier.procedure

    # mettre dans le modele
    @commentaires = @dossier.commentaires.order(created_at: :desc)

    @commentaires = @commentaires.all.decorate

    #TODO load user email
    @commentaire_email = 'user@email'
  rescue ActiveRecord::RecordNotFound
    flash.alert = t('errors.messages.dossier_not_found')
    redirect_to url_for(root_path)
  end

  def submit
    show

    @dossier.next_step! 'user', 'submit'
    flash.notice = 'Dossier soumis avec succès.'

    render 'show'
  end

  def submit_validate
    show

    @dossier.next_step! 'user', 'submit_validate'
    flash.notice = 'Dossier déposé avec succès.'

    render 'show'
  end
end
