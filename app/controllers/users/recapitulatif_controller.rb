class Users::RecapitulatifController < UsersController
  before_action :authorized_routes?, only: [:show]

  def show
    create_dossier_facade
  end

  def initiate
    create_dossier_facade

    @facade.dossier.next_step! 'user', 'initiate'
    flash.notice = 'Dossier soumis avec succès.'

    render 'show'
  end

  def submit
    create_dossier_facade

    @facade.dossier.next_step! 'user', 'submit'
    flash.notice = 'Dossier déposé avec succès.'

    NotificationMailer.dossier_submitted(@facade.dossier).deliver_now!

    render 'show'
  end

  private

  def create_dossier_facade
    @facade = DossierFacades.new current_user_dossier.id, current_user.email

  rescue ActiveRecord::RecordNotFound
    flash.alert = t('errors.messages.dossier_not_found')
    redirect_to url_for(root_path)
  end
end
