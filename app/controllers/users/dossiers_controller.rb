class Users::DossiersController < UsersController
  include SmartListing::Helper::ControllerExtensions
  helper SmartListing::Helper

  before_action :authenticate_user!, except: :commencer
  before_action :check_siret, only: :siret_informations

  before_action only: [:show] do
    authorized_routes? self.class
  end

  def index
    cookies[:liste] = param_liste

    @dossiers_list_facade = DossiersListFacades.new current_user, param_liste

    unless DossiersListUserService.dossiers_liste_libelle.include?(param_liste)
      cookies[:liste] = 'a_traiter'
      return redirect_to users_dossiers_path
    end

    @dossiers = smart_listing_create :dossiers,
                                     @dossiers_list_facade.dossiers_to_display,
                                     partial: "users/dossiers/list",
                                     array: true
  end

  def commencer
    unless params[:procedure_path].nil?
      procedure = ProcedurePath.where(path: params[:procedure_path]).first!.procedure
    end

    if procedure.archived?

      @dossier = Dossier.new(procedure: procedure)

      return render 'commencer/archived'
    end

    redirect_to new_users_dossier_path(procedure_id: procedure.id)
  rescue ActiveRecord::RecordNotFound
    error_procedure
  end

  def new
    procedure = Procedure.where(archived: false, published: true).find(params[:procedure_id])

    dossier = Dossier.create(procedure: procedure, user: current_user, state: 'draft')
    siret = params[:siret] || current_user.siret

    update_current_user_siret! siret unless siret.nil?

    redirect_to users_dossier_path(id: dossier.id)
  rescue ActiveRecord::RecordNotFound
    error_procedure
  end

  def show
    @facade = facade
    @siret = current_user.siret unless current_user.siret.nil?

    if @facade.procedure.for_individual? && current_user.loged_in_with_france_connect?
      individual = @facade.dossier.individual

      individual.update_column :gender, @facade.dossier.france_connect_information.gender
      individual.update_column :nom, @facade.dossier.france_connect_information.family_name
      individual.update_column :prenom, @facade.dossier.france_connect_information.given_name
      individual.update_column :birthdate, @facade.dossier.france_connect_information.birthdate.strftime("%d/%m/%Y")
    end

  rescue ActiveRecord::RecordNotFound
    flash.alert = t('errors.messages.dossier_not_found')
    redirect_to url_for users_dossiers_path
  end

  def siret_informations
    @facade = facade params[:dossier_id]

    update_current_user_siret! siret

    dossier = DossierService.new(@facade.dossier, siret, current_user.france_connect_information).dossier_informations!

    if dossier.entreprise.nil? || dossier.etablissement.nil?
      return errors_valid_siret
    end

    @facade = facade params[:dossier_id]

    if @facade.procedure.individual_with_siret?
      render '/dossiers/add_siret', formats: 'js'
    else
      render '/dossiers/new_siret', formats: 'js'
    end
  rescue RestClient::ResourceNotFound, RestClient::BadRequest
    errors_valid_siret

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

    if checked_autorisation_donnees?
      begin
        @facade.dossier.update_attributes!(update_params)
      rescue
        flash.now.alert = @facade.dossier.errors.full_messages.join('<br />').html_safe
        return render 'show'
      end
      if @facade.dossier.procedure.module_api_carto.use_api_carto
        redirect_to url_for(controller: :carte, action: :show, dossier_id: @facade.dossier.id)
      else
        redirect_to url_for(controller: :description, action: :show, dossier_id: @facade.dossier.id)
      end
    else
      flash.alert = 'Les conditions sont obligatoires.'
      redirect_to users_dossier_path(id: @facade.dossier.id)
    end
  end

  def self.route_authorization
    {
        states: [:draft]
    }
  end

  def destroy
    dossier = current_user.dossiers.find(params[:id])
    if dossier.brouillon?
      dossier.destroy
      flash.notice = 'Brouillon supprimé'
    end
    redirect_to url_for users_dossiers_path
  end

  private

  def check_siret
    errors_valid_siret unless Siret.new(siret: siret).valid?
  end

  def errors_valid_siret
    flash.alert = t('errors.messages.invalid_siret')
    @facade = facade params[:dossier_id]

    render '/dossiers/new_siret', formats: :js, locals: {invalid_siret: siret}
  end

  def update_params
    params.require(:dossier).permit(:id, :autorisation_donnees, individual_attributes: [:gender, :nom, :prenom, :birthdate])
  end

  def checked_autorisation_donnees?
    update_params[:autorisation_donnees] == '1'
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

  def update_current_user_siret! siret
    current_user.update_attributes(siret: siret)
  end

  def facade id = params[:id]
    DossierFacades.new id, current_user.email
  end

  def param_liste
    @liste ||= params[:liste] || cookies[:liste] || 'a_traiter'
  end
end
