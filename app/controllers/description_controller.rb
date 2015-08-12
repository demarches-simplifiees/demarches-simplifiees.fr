class DescriptionController < ApplicationController
  def show
    @dossier = Dossier.find(params[:dossier_id])
    @dossier = @dossier.decorate

    @array_id_pj_valides = DossierPdf.get_array_id_pj_valid_for_dossier @dossier.id

    @liste_pieces_jointes = get_liste_piece_jointe
  rescue
    redirect_to url_for({controller: :start, action: :error_dossier})
  end

  def error
    show
    flash.now.alert = 'Un ou plusieurs attributs obligatoires sont manquants ou incorrects.'
    render 'show'
  end

  def create
    @dossier = Dossier.find(params[:dossier_id])
    @dossier.update_attributes(create_params)

    if params[:cerfa_pdf] != nil
      DossierPdf.destroy_all(dossier_id: @dossier.id, ref_pieces_jointes_id: 0)
      @dossier_pdf = DossierPdf.new
      @dossier_pdf.ref_dossier_pdf = params[:cerfa_pdf]
      @dossier_pdf.ref_pieces_jointes_id = 0
      @dossier_pdf.dossier = @dossier
      @dossier_pdf.save
    end

    get_liste_piece_jointe.each do |pj|
      if params["piece_jointe_#{pj.id}"] != nil
        DossierPdf.destroy_all(dossier_id: @dossier.id, ref_pieces_jointes_id: pj.id)

        @dossier_pdf = DossierPdf.new
        @dossier_pdf.ref_dossier_pdf = params["piece_jointe_#{pj.id}"]
        @dossier_pdf.ref_pieces_jointes_id = pj.id
        @dossier_pdf.dossier = @dossier
        @dossier_pdf.save
      end
    end

    if check_missing_attributes(params)||check_format_email(@dossier.mail_contact) == nil
      redirect_to url_for({controller: :description, action: :error})
    else
      if params[:back_url] == 'recapitulatif'
        @commentaire = Commentaire.create
        @commentaire.email = 'Modification détails'
        @commentaire.body = 'Les informations détaillées de la demande ont été modifiées. Merci de le prendre en compte.'
        @commentaire.dossier = @dossier
        @commentaire.save
      end

      redirect_to url_for({controller: :recapitulatif, action: :show, dossier_id: @dossier.id})
    end
  end

  private

  def create_params
    params.permit(:nom_projet, :description, :montant_projet, :montant_aide_demande, :date_previsionnelle, :lien_plus_infos, :mail_contact)
  end

  #TODO dans un validateur, dans le model
  def check_missing_attributes params
    params[:nom_projet].strip == '' || params[:description].strip == '' || params[:montant_projet].strip == '' || params[:montant_aide_demande].strip == '' || params[:date_previsionnelle].strip == '' || params[:mail_contact].strip == ''
  end

  #TODO dans un validateur, dans le model
  def check_format_email email
    /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/.match(email)
  end

  def get_liste_piece_jointe
    @formulaire = RefFormulaire.find(@dossier.ref_formulaire)
    RefPiecesJointe.where ("\"CERFA\" = '#{@formulaire.ref_demarche}'")
  end
end
