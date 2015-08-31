class DescriptionController < ApplicationController
  def show
    @dossier = Dossier.find(params[:dossier_id])
    @dossier = @dossier.decorate

    @formulaire = @dossier.formulaire

  rescue ActiveRecord::RecordNotFound
    redirect_to url_for(controller: :start, action: :error_dossier)
  end

  def error
    show
    flash.now.alert = 'Un ou plusieurs attributs obligatoires sont manquants ou incorrects.'
    render 'show'
  end

  def create
    @dossier = Dossier.find(params[:dossier_id])
    unless  @dossier.update_attributes(create_params)
      @dossier = @dossier.decorate
      @formulaire = @dossier.formulaire

      flash.now.alert = @dossier.errors.full_messages.join('<br />').html_safe
      return render 'show'
    end
    unless params[:cerfa_pdf].nil?
      cerfa = @dossier.cerfa
      cerfa.content = params[:cerfa_pdf]
      cerfa.save
    end

    @dossier.pieces_jointes.each do |piece_jointe|
      unless params["piece_jointe_#{piece_jointe.type}"].nil?
        piece_jointe.content = params["piece_jointe_#{piece_jointe.type}"]
        piece_jointe.save
      end
    end

      if params[:back_url] == 'recapitulatif'
        commentaire = Commentaire.create
        commentaire.email = 'Modification détails'
        commentaire.body = 'Les informations détaillées de la demande ont été modifiées. Merci de le prendre en compte.'
        commentaire.dossier = @dossier
        commentaire.save
      end

      redirect_to url_for(controller: :recapitulatif, action: :show, dossier_id: @dossier.id)

  end

  private

  def create_params
    params.permit(:nom_projet, :description, :montant_projet, :montant_aide_demande, :date_previsionnelle, :lien_plus_infos, :mail_contact)
  end
end
