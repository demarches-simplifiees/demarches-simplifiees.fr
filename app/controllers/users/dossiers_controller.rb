class Users::DossiersController < UsersController
  include SmartListing::Helper::ControllerExtensions
  helper SmartListing::Helper

  SESSION_USER_RETURN_LOCATION = 'user_return_to'

  before_action :store_user_location!, only: :new
  before_action :authenticate_user!, except: [:commencer, :commencer_test]
  before_action :check_siret, only: :siret_informations

  before_action only: [:show] do
    authorized_routes? self.class
  end

  def commencer_test
    procedure_path = ProcedurePath.find_by(path: params[:procedure_path])
    procedure = procedure_path&.procedure

    if procedure&.brouillon_avec_lien?
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

        render 'commencer/archived'
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
    siret = params[:siret] || current_user.siret

    if siret.present?
      update_current_user_siret! siret
    end

    if dossier.procedure.for_individual
      redirect_to identite_dossier_path(dossier)
    else
      redirect_to users_dossier_path(id: dossier.id)
    end
  rescue ActiveRecord::RecordNotFound
    error_procedure
  end

  def show
    @facade = facade
    if current_user.siret.present?
      @siret = current_user.siret
    end

    if @facade.procedure.for_individual? && current_user.loged_in_with_france_connect?
      individual = @facade.dossier.individual

      individual.update_column :gender, @facade.dossier.france_connect_information.gender
      individual.update_column :nom, @facade.dossier.france_connect_information.family_name
      individual.update_column :prenom, @facade.dossier.france_connect_information.given_name

      individual.birthdate = @facade.dossier.france_connect_information.birthdate
      individual.save
    end

  rescue ActiveRecord::RecordNotFound
    flash.alert = t('errors.messages.dossier_not_found')
    redirect_to url_for dossiers_path
  end

  def siret_informations
    @facade = facade params[:dossier_id]

    update_current_user_siret!(siret)

    etablissement_attributes = ApiEntrepriseService.get_etablissement_params_for_siret(siret, @facade.dossier.procedure_id)

    if etablissement_attributes.present?
      etablissement_attributes = ActionController::Parameters.new(etablissement_attributes).permit!
      etablissement = @facade.dossier.build_etablissement(etablissement_attributes)
      if !etablissement.save
        return errors_valid_siret
      end
    else
      return errors_valid_siret
    end

    @facade = facade params[:dossier_id]

    if @facade.procedure.individual_with_siret?
      render '/dossiers/add_siret', formats: 'js'
    else
      render '/dossiers/new_siret', formats: 'js'
    end
  rescue ActiveRecord::RecordNotFound
    flash.alert = t('errors.messages.dossier_not_found')
    redirect_to url_for dossiers_path
  end

  def change_siret
    Dossier.find(params[:dossier_id]).reset!

    @facade = facade params[:dossier_id]

    if @facade.procedure.individual_with_siret?
      render '/dossiers/add_siret', formats: 'js'
    else
      render '/dossiers/new_siret', formats: 'js'
    end
  end

  def update
    @facade = facade params[:dossier][:id]
    @facade.dossier.update!(autorisation_donnees: true)

    if @facade.dossier.procedure.module_api_carto.use_api_carto
      redirect_to url_for(controller: :carte, action: :show, dossier_id: @facade.dossier.id)
    else
      redirect_to brouillon_dossier_path(@facade.dossier)
    end
  end

  def self.route_authorization
    {
      states: [Dossier.states.fetch(:brouillon)]
    }
  end

  def destroy
    dossier = current_user.dossiers.find(params[:id])
    if dossier.brouillon?
      dossier.destroy
      flash.notice = 'Brouillon supprimé'
    end
    redirect_to url_for dossiers_path
  end

  private

  def check_siret
    if !Siret.new(siret: siret).valid?
      errors_valid_siret
    end
  end

  def errors_valid_siret
    flash.alert = t('errors.messages.invalid_siret')
    @facade = facade params[:dossier_id]

    render '/dossiers/new_siret', formats: :js, locals: { invalid_siret: siret }
  end

  def siret
    create_params[:siret]
  end

  def create_params
    params.require(:dossier).permit(:siret)
  end

  def error_procedure
    flash.alert = t('errors.messages.procedure_not_found')

    redirect_to url_for dossiers_path
  end

  def update_current_user_siret!(siret)
    current_user.update(siret: siret)
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
