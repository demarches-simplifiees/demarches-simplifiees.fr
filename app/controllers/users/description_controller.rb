class Users::DescriptionController < UsersController
  before_action only: [:show] do
    authorized_routes? self.class
  end

  def show
    @dossier = current_user_dossier
    @dossier = @dossier.decorate

    @procedure = @dossier.procedure
    @champs = @dossier.ordered_champs

  rescue ActiveRecord::RecordNotFound
    flash.alert = t('errors.messages.dossier_not_found')
    redirect_to url_for(root_path)
  end

  def error
    show
    flash.now.alert = 'Un ou plusieurs attributs obligatoires sont manquants ou incorrects.'
    render 'show'
  end

  def create
    @dossier = current_user_dossier
    @procedure = @dossier.procedure
    
    unless @dossier.update_attributes(create_params)
      @dossier = @dossier.decorate
      @procedure = @dossier.procedure

      flash.now.alert = @dossier.errors.full_messages.join('<br />').html_safe
      return render 'show'
    end

    if @procedure.cerfa_flag?
      unless params[:cerfa_pdf].nil?
        cerfa = @dossier.cerfa
        cerfa.content = params[:cerfa_pdf]
        cerfa.save
      end
    end

    unless params[:champs].nil?
      @dossier.champs.each do |champ|
        champ.value = params[:champs]["'#{champ.id}'"]
        champ.save
      end
    end

    @dossier.pieces_justificatives.each do |piece_justificative|
      unless params["piece_justificative_#{piece_justificative.type}"].nil?
        piece_justificative.content = params["piece_justificative_#{piece_justificative.type}"]
        piece_justificative.save
      end
    end

    if @dossier.draft?
      @dossier.initiated!
    end

    flash.notice = 'Félicitation, votre demande a bien été enregistrée.'
    redirect_to url_for(controller: :recapitulatif, action: :show, dossier_id: @dossier.id)
  end

  def self.route_authorization
    {
        states: [:draft, :initiated, :replied, :updated]
    }
  end

  private

  def create_params
    params.permit(:nom_projet, :description)
  end
end
