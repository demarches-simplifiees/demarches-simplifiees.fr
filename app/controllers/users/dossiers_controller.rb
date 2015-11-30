class Users::DossiersController < UsersController
  before_action :authenticate_user!

  def show
    @dossier = current_user_dossier params[:id]

    @etablissement =  @dossier.etablissement
    @entreprise =  @dossier.entreprise.decorate
  rescue ActiveRecord::RecordNotFound
    flash.alert = t('errors.messages.dossier_not_found')
    redirect_to url_for(controller: :siret)
  end

  def create
    procedure = Procedure.find(params['procedure_id'])
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

    @dossier = Dossier.create(user: current_user)
    @dossier.draft!

    @dossier.procedure = procedure
    @dossier.save

    @entreprise.dossier = @dossier
    @entreprise.save

    @etablissement.dossier = @dossier
    @etablissement.entreprise = @entreprise
    @etablissement.save

    redirect_to url_for(controller: :dossiers, action: :show, id: @dossier.id)

  rescue RestClient::ResourceNotFound
    flash.alert = t('errors.messages.invalid_siret')
    redirect_to url_for(controller: :siret, procedure_id: params['procedure_id'])
  rescue ActiveRecord::RecordNotFound
    flash.alert = t('errors.messages.dossier_not_found')
    redirect_to url_for(controller: :siret)
  end

  def update

    @dossier = current_user_dossier params[:id]
    if checked_autorisation_donnees?
      @dossier.update_attributes(update_params)

      if @dossier.procedure.use_api_carto
        redirect_to url_for(controller: :carte, action: :show, dossier_id: @dossier.id)
      else
        redirect_to url_for(controller: :description, action: :show, dossier_id: @dossier.id)
      end
    else
      @etablissement =  @dossier.etablissement
      @entreprise =  @dossier.entreprise.decorate
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

  def a_traiter
    @dossiers_a_traiter = current_user.dossiers.waiting_for_user
    @dossiers = @dossiers_a_traiter

    params[:page] = 1 if params[:page].nil?

    @dossiers = @dossiers.paginate(:page => params[:page], :per_page => 12).decorate
    total_dossiers_per_state
  end

  def en_attente
    @dossiers_en_attente = current_user.dossiers.waiting_for_gestionnaire
    @dossiers = @dossiers_en_attente

    params[:page] = 1 if params[:page].nil?

    @dossiers = @dossiers.paginate(:page => params[:page], :per_page => 12).decorate
    total_dossiers_per_state
  end

  def termine
    @dossiers_termine = current_user.dossiers.termine
    @dossiers = @dossiers_termine

    params[:page] = 1 if params[:page].nil?

    @dossiers = @dossiers.paginate(:page => params[:page], :per_page => 12).decorate
    total_dossiers_per_state
  end

  private

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
    params[:siret]
  end

  def siren
    siret[0..8]
  end

  def total_dossiers_per_state
    @dossiers_a_traiter_total = !@dossiers_a_traiter.nil? ? @dossiers_a_traiter.size : current_user.dossiers.waiting_for_user().size
    @dossiers_en_attente_total = !@dossiers_en_attente.nil? ? @dossiers_en_attente.size : current_user.dossiers.waiting_for_gestionnaire().size
    @dossiers_termine_total = !@dossiers_termine.nil? ? @dossiers_termine.size : current_user.dossiers.termine().size
  end
end
