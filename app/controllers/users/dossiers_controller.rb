class Users::DossiersController < UsersController
  include SmartListing::Helper::ControllerExtensions
  helper SmartListing::Helper

  before_action :authenticate_user!
  before_action :check_siret, only: :create

  def index
    order = 'DESC'

    @liste = params[:liste] || 'a_traiter'

    @dossiers = smart_listing_create :dossiers,
                                     dossiers_to_display,
                                     partial: "users/dossiers/list",
                                     array: true

    total_dossiers_per_state
  end

  def new
    procedure = Procedure.where(archived: false).find(params[:procedure_id])

    @dossier = Dossier.new(procedure: procedure)
    @siret = params[:siret] || current_user.siret

  rescue ActiveRecord::RecordNotFound
    error_procedure
  end

  def show
    @facade = DossierFacades.new params[:id], current_user.email

  rescue ActiveRecord::RecordNotFound
    flash.alert = t('errors.messages.dossier_not_found')
    redirect_to url_for users_dossiers_path
  end

  def create
    etablissement = Etablissement.new(SIADE::EtablissementAdapter.new(siret).to_params)
    entreprise = Entreprise.new(SIADE::EntrepriseAdapter.new(siren).to_params)
    rna_information = SIADE::RNAAdapter.new(siret).to_params
    exercices = SIADE::ExercicesAdapter.new(siret).to_params
    mandataires_sociaux = SIADE::MandatairesSociauxAdapter.new(siren).to_params

    unless exercices.nil?
      exercices.each_value do |exercice|
        exercice = Exercice.new(exercice)
        exercice.etablissement = etablissement
        exercice.save
      end
    end
    mandataire_social = false

    mandataires_sociaux.each do |k, mandataire|
      break mandataire_social = true if !current_user.france_connect_particulier_id.nil? &&
          mandataire[:nom] == current_user.family_name &&
          mandataire[:prenom] == current_user.given_name &&
          mandataire[:date_naissance_timestamp] == current_user.birthdate.to_time.to_i

    end

    dossier = Dossier.create(user: current_user, state: 'draft', procedure_id: create_params[:procedure_id], mandataire_social: mandataire_social)

    entreprise.dossier = dossier
    entreprise.save

    unless rna_information.nil?
      rna_information = RNAInformation.new(rna_information)
      rna_information.entreprise = entreprise
      rna_information.save
    end

    etablissement.dossier = dossier
    etablissement.entreprise = entreprise
    etablissement.save

    redirect_to url_for(controller: :dossiers, action: :show, id: dossier.id)

  rescue RestClient::ResourceNotFound
    errors_valid_siret

  rescue ActiveRecord::RecordNotFound
    flash.alert = t('errors.messages.dossier_not_found')
    redirect_to url_for(controller: :siret)
  end

  def update
    @facade = DossierFacades.new params[:id], current_user.email

    if checked_autorisation_donnees?
      @facade.dossier.update_attributes(update_params)

      if @facade.dossier.procedure.module_api_carto.use_api_carto
        redirect_to url_for(controller: :carte, action: :show, dossier_id: @facade.dossier.id)
      else
        redirect_to url_for(controller: :description, action: :show, dossier_id: @facade.dossier.id)
      end
    else
      flash.now.alert = 'Les conditions sont obligatoires.'
      render 'show'
    end
  end

  def archive
    dossier = current_user.dossiers.find(params[:dossier_id])
    dossier.update_attributes({archived: true})

    flash.notice = 'Dossier archivé'
    redirect_to users_dossiers_path

  rescue ActiveRecord::RecordNotFound
    flash.alert = 'Dossier inéxistant'
    redirect_to users_dossiers_path
  end

  private

  def dossiers_to_display
    {'a_traiter' => waiting_for_user,
     'en_attente' => waiting_for_gestionnaire,
     'termine' => termine}[@liste]
  end

  def waiting_for_user
    @a_traiter_class = (@liste == 'a_traiter' ? 'active' : '')
    @waiting_for_user ||= current_user.dossiers.waiting_for_user 'DESC'
  end

  def waiting_for_gestionnaire
    @en_attente_class = (@liste == 'en_attente' ? 'active' : '')
    @waiting_for_gestionnaire ||= current_user.dossiers.waiting_for_gestionnaire 'DESC'
  end

  def termine
    @termine_class = (@liste == 'termine' ? 'active' : '')
    @termine ||= current_user.dossiers.termine 'DESC'
  end

  def total_dossiers_per_state
    @dossiers_a_traiter_total = waiting_for_user.count
    @dossiers_en_attente_total = waiting_for_gestionnaire.count
    @dossiers_termine_total = termine.count
  end

  def check_siret
    errors_valid_siret unless Siret.new(siret: siret).valid?
  end

  def errors_valid_siret
    flash.alert = t('errors.messages.invalid_siret')
    redirect_to url_for new_users_dossiers_path(procedure_id: create_params[:procedure_id])
  end

  def update_params
    params.require(:dossier).permit(:autorisation_donnees)
  end

  def checked_autorisation_donnees?
    update_params[:autorisation_donnees] == '1'
  end

  def siret
    create_params[:siret]
  end

  def siren
    siret[0..8]
  end

  def create_params
    params.require(:dossier).permit(:siret, :procedure_id)
  end

  def error_procedure
    flash.alert = t('errors.messages.procedure_not_found')

    redirect_to url_for users_dossiers_path
  end
end
