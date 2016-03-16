class Users::DescriptionController < UsersController
  before_action only: [:show] do
    authorized_routes? self.class
  end

  def show
    @dossier = current_user_dossier.decorate

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
    @champs = @dossier.ordered_champs

    unless @dossier.update_attributes(create_params)
      @dossier = @dossier.decorate

      flash.now.alert = @dossier.errors.full_messages.join('<br />').html_safe
      return render 'show'
    end

    if @procedure.cerfa_flag?
      unless params[:cerfa_pdf].nil?
        cerfa = Cerfa.new(content: params[:cerfa_pdf], dossier: @dossier)
        unless cerfa.save
          flash.now.alert = cerfa.errors.full_messages.join('<br />').html_safe
          return render 'show'
        end
      end
    end

    unless params[:champs].nil?
      @dossier.champs.each do |champ|
        champ.value = params[:champs]["'#{champ.id}'"]

        if champ.mandatory? && (champ.value.nil? || champ.value.blank?)
          flash.now.alert = "Le champ #{champ.libelle} doit être rempli."
          return render 'show'
        end

        champ.save
      end
    end

    @dossier.pieces_justificatives.each do |piece_justificative|
      unless params["piece_justificative_#{piece_justificative.type}"].nil?
        piece_justificative.content = params["piece_justificative_#{piece_justificative.type}"]
        unless piece_justificative.save
          flash.now.alert = piece_justificative.errors.full_messages.join('<br />').html_safe
          return render 'show'
        end
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
