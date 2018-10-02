class Users::RecapitulatifController < UsersController
  before_action only: [:show] do
    authorized_routes? self.class
  end

  def show
    redirect_to dossier_url(current_user_dossier)
  end

  def initiate
    create_dossier_facade

    @facade.dossier.en_construction!
    flash.notice = 'Dossier soumis avec succès.'

    redirect_to users_dossier_recapitulatif_path
  end

  def self.route_authorization
    {
      states: [
        Dossier.states.fetch(:en_construction),
        Dossier.states.fetch(:en_instruction),
        Dossier.states.fetch(:sans_suite),
        Dossier.states.fetch(:accepte),
        Dossier.states.fetch(:refuse)
      ]
    }
  end

  private

  def create_dossier_facade
    @facade = DossierFacades.new current_user_dossier.id, current_user.email

  rescue ActiveRecord::RecordNotFound
    flash.alert = t('errors.messages.dossier_not_found')
    redirect_to url_for(root_path)
  end
end
