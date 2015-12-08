class Users::DossiersController < UsersController
  before_action :authenticate_user!
  before_action :check_siret, only: :create

  def index
    order = 'DESC'

    if params[:liste] == 'a_traiter' || params[:liste].nil?
      @dossiers = current_user.dossiers.waiting_for_user order
      @dossiers_a_traiter = @dossiers

      @liste = 'a_traiter'

    elsif params[:liste] == 'en_attente'
      @dossiers = current_user.dossiers.waiting_for_gestionnaire order
      @dossiers_en_attente = @dossiers

      @liste = 'en_attente'

    elsif params[:liste] == 'termine'

      @dossiers = current_user.dossiers.termine order
      @dossiers_termine = @dossiers

      @liste = 'termine'
    end

    @dossiers = @dossiers.paginate(:page => (params[:page] || 1)).decorate
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
    @dossier = current_user_dossier params[:id]

    @etablissement = @dossier.etablissement
    @entreprise = @dossier.entreprise.decorate
  rescue ActiveRecord::RecordNotFound
    flash.alert = t('errors.messages.dossier_not_found')
    redirect_to url_for users_dossiers_path
  end

  def create
    @etablissement = Etablissement.new(SIADE::EtablissementAdapter.new(siret).to_params)
    @entreprise = Entreprise.new(SIADE::EntrepriseAdapter.new(siren).to_params)

    exercices = SIADE::ExercicesAdapter.new(siret).to_params

    unless exercices.nil?
      exercices.each_value do |exercice|
        exercice = Exercice.new(exercice)
        exercice.etablissement = @etablissement
        exercice.save
      end
    end

    @dossier = Dossier.create(user: current_user, state: 'draft', procedure_id: create_params[:procedure_id])

    @entreprise.dossier = @dossier
    @entreprise.save

    @etablissement.dossier = @dossier
    @etablissement.entreprise = @entreprise
    @etablissement.save

    redirect_to url_for(controller: :dossiers, action: :show, id: @dossier.id)

  rescue RestClient::ResourceNotFound
    errors_valid_siret

  rescue ActiveRecord::RecordNotFound
    flash.alert = t('errors.messages.dossier_not_found')
    redirect_to url_for(controller: :siret)
  end

  def update

    @dossier = current_user_dossier params[:id]
    if checked_autorisation_donnees?
      @dossier.update_attributes(update_params)

      if @dossier.procedure.module_api_carto.use_api_carto
        redirect_to url_for(controller: :carte, action: :show, dossier_id: @dossier.id)
      else
        redirect_to url_for(controller: :description, action: :show, dossier_id: @dossier.id)
      end
    else
      @etablissement = @dossier.etablissement
      @entreprise = @dossier.entreprise.decorate
      flash.now.alert = 'Les conditions sont obligatoires.'
      render 'show'
    end
  end

  def archive
    @dossier = current_user.dossiers.find(params[:dossier_id])
    @dossier.update_attributes({archived: true})

    flash.notice = 'Dossier archivé'
    redirect_to users_dossiers_path

  rescue ActiveRecord::RecordNotFound
    flash.alert = 'Dossier inéxistant'
    redirect_to users_dossiers_path
  end

  private

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

  def dossier_id_is_present?
    @dossier_id != ''
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

  def total_dossiers_per_state
    @dossiers_a_traiter_total = !@dossiers_a_traiter.nil? ? @dossiers_a_traiter.size : current_user.dossiers.waiting_for_user.size
    @dossiers_en_attente_total = !@dossiers_en_attente.nil? ? @dossiers_en_attente.size : current_user.dossiers.waiting_for_gestionnaire.size
    @dossiers_termine_total = !@dossiers_termine.nil? ? @dossiers_termine.size : current_user.dossiers.termine.size
  end

  def create_params
    params.require(:dossier).permit(:siret, :procedure_id)
  end

  def error_procedure
    render :file => "#{Rails.root}/public/404_procedure_not_found.html",  :status => 404
  end
end
