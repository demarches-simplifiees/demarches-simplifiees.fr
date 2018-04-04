class Users::DossiersController < UsersController
  include SmartListing::Helper::ControllerExtensions
  helper SmartListing::Helper

  before_action :authenticate_user!, except: :commencer
  before_action :check_siret, only: :siret_informations

  before_action only: [:show] do
    authorized_routes? self.class
  end

  def index
    @liste ||= params[:liste] || 'a_traiter'

    @user_dossiers = current_user.dossiers

    @dossiers_filtered = case @liste
    when 'brouillon'
      @user_dossiers.state_brouillon.order_by_updated_at
    when 'a_traiter'
      @user_dossiers.state_en_construction.order_by_updated_at
    when 'en_instruction'
      @user_dossiers.state_en_instruction.order_by_updated_at
    when 'termine'
      @user_dossiers.state_termine.order_by_updated_at
    when 'invite'
      current_user.invites
    else
      return redirect_to users_dossiers_path
    end

    # FIXME: remove when
    # https://github.com/Sology/smart_listing/issues/134
    # is fixed
    permit_smart_listing_params
    # END OF FIXME

    @dossiers = smart_listing_create :dossiers,
      @dossiers_filtered,
      partial: "users/dossiers/list",
      array: true
  end

  def commencer
    if params[:procedure_path].present?
      procedure_path = ProcedurePath.where(path: params[:procedure_path]).last

      if procedure_path.nil? || procedure_path.procedure.nil?
        flash.alert = "Procédure inconnue"
        return redirect_to root_path
      else
        procedure = procedure_path.procedure
      end
    end

    if procedure.archivee?

      @dossier = Dossier.new(procedure: procedure)

      return render 'commencer/archived'
    end

    redirect_to new_users_dossier_path(procedure_id: procedure.id)
  rescue ActiveRecord::RecordNotFound
    error_procedure
  end

  def new
    procedure = Procedure.publiees.find(params[:procedure_id])

    dossier = Dossier.create(procedure: procedure, user: current_user, state: 'brouillon')
    siret = params[:siret] || current_user.siret

    update_current_user_siret! siret if siret.present?

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
    @siret = current_user.siret if current_user.siret.present?

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
    redirect_to url_for users_dossiers_path
  end

  def siret_informations
    @facade = facade params[:dossier_id]

    update_current_user_siret!(siret)

    etablissement_attributes = SIRETService.fetch(siret, @facade.dossier.procedure_id, @facade.dossier)

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
    redirect_to url_for users_dossiers_path
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

    if individual_errors.any?
      flash.alert = individual_errors
      redirect_to users_dossier_path(id: @facade.dossier.id)
    else
      if !Dossier.find(@facade.dossier.id).update(update_params)
        flash.alert = @facade.dossier.errors.full_messages

        return redirect_to users_dossier_path(id: @facade.dossier.id)
      end

      if @facade.dossier.procedure.module_api_carto.use_api_carto
        redirect_to url_for(controller: :carte, action: :show, dossier_id: @facade.dossier.id)
      else
        redirect_to modifier_dossier_path(@facade.dossier)
      end
    end
  end

  def self.route_authorization
    {
      states: [:brouillon]
    }
  end

  def destroy
    dossier = current_user.dossiers.find(params[:id])
    if dossier.brouillon?
      dossier.destroy
      flash.notice = 'Brouillon supprimé'
    end
    redirect_to url_for users_dossiers_path(liste: 'brouillon')
  end

  def text_summary
    dossier = Dossier.find(params[:dossier_id])
    render json: { textSummary: dossier.text_summary }
  rescue ActiveRecord::RecordNotFound
    render json: {}, status: 404
  end

  private

  def check_siret
    errors_valid_siret if !Siret.new(siret: siret).valid?
  end

  def errors_valid_siret
    flash.alert = t('errors.messages.invalid_siret')
    @facade = facade params[:dossier_id]

    render '/dossiers/new_siret', formats: :js, locals: { invalid_siret: siret }
  end

  def update_params
    params.require(:dossier).permit(:id, :autorisation_donnees)
  end

  def individual_errors
    errors = []

    if update_params[:autorisation_donnees] != "1"
      errors << "La validation des conditions d'utilisation est obligatoire"
    end

    errors
  end

  def siret
    create_params[:siret]
  end

  def create_params
    params.require(:dossier).permit(:siret)
  end

  def error_procedure
    flash.alert = t('errors.messages.procedure_not_found')

    redirect_to url_for users_dossiers_path
  end

  def update_current_user_siret!(siret)
    current_user.update(siret: siret)
  end

  def facade(id = params[:id])
    DossierFacades.new id, current_user.email
  end
end
