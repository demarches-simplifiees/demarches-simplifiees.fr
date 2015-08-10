class DescriptionController < ApplicationController
  def show
    @dossier = Dossier.find(params[:dossier_id])
    @dossier = @dossier.decorate
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

    @dossier.nom_projet = params[:nom_projet]
    @dossier.description = params[:description]
    @dossier.montant_projet = params[:montant_projet]
    @dossier.montant_aide_demande = params[:montant_aide_demande]
    @dossier.date_previsionnelle = params[:date_previsionnelle]
    @dossier.lien_plus_infos = params[:lien_plus_infos]
    @dossier.mail_contact = params[:mail_contact]

    @dossier.save

    #upload dossier pdf

    @dossier_pdf = DossierPdf.new
    @dossier_pdf.ref_dossier_pdf = params[:dossier_pdf]
    @dossier_pdf.dossier = @dossier
    @dossier_pdf.save!

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

  def check_missing_attributes params
    params[:nom_projet].strip == '' || params[:description].strip == '' || params[:montant_projet].strip == '' || params[:montant_aide_demande].strip == '' || params[:date_previsionnelle].strip == '' || params[:mail_contact].strip == ''
  end

  def check_format_email email
    /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z]+)*\.[a-z]+\z/.match(email)
  end
end
