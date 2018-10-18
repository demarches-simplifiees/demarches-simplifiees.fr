class Users::DossiersController < UsersController
  include SmartListing::Helper::ControllerExtensions
  helper SmartListing::Helper

  SESSION_USER_RETURN_LOCATION = 'user_return_to'

  before_action :store_user_location!, only: :new
  before_action :authenticate_user!, except: [:commencer, :commencer_test]

  before_action only: [:show] do
    authorized_routes? self.class
  end

  def commencer_test
    procedure_path = ProcedurePath.find_by(path: params[:procedure_path])
    procedure = procedure_path&.procedure

    if procedure&.brouillon? && procedure&.path.present?
      redirect_to new_users_dossier_path(procedure_id: procedure.id, brouillon: true)
    else
      flash.alert = "La démarche est inconnue."
      redirect_to root_path
    end
  end

  def commencer
    procedure_path = ProcedurePath.find_by(path: params[:procedure_path])
    procedure = procedure_path&.procedure

    if procedure.present?
      if procedure.archivee?
        @dossier = Dossier.new(procedure: procedure)

        render 'commencer/archived', layout: 'commencer'
      else
        redirect_to new_users_dossier_path(procedure_id: procedure.id)
      end
    else
      flash.alert = "La démarche est inconnue, ou la création de nouveaux dossiers pour cette démarche est terminée."
      redirect_to root_path
    end
  end

  def new
    erase_user_location!

    if params[:brouillon]
      procedure = Procedure.brouillon.find(params[:procedure_id])
    else
      procedure = Procedure.publiees.find(params[:procedure_id])
    end

    dossier = Dossier.create!(procedure: procedure, user: current_user, state: Dossier.states.fetch(:brouillon))

    if dossier.procedure.for_individual
      redirect_to identite_dossier_path(dossier)
    else
      redirect_to siret_dossier_path(id: dossier.id)
    end
  rescue ActiveRecord::RecordNotFound
    error_procedure
  end

  def self.route_authorization
    {
      states: [Dossier.states.fetch(:brouillon)]
    }
  end

  private

  def error_procedure
    flash.alert = t('errors.messages.procedure_not_found')

    redirect_to url_for dossiers_path
  end

  def facade(id = params[:id])
    DossierFacades.new id, current_user.email
  end

  def store_user_location!
    store_location_for(:user, request.fullpath)
  end

  def erase_user_location!
    session.delete(SESSION_USER_RETURN_LOCATION)
  end
end
