require 'prawn/measurement_extensions'

#----- A4 page size
page_size = 'A4'
page_width = 595

#----- margins
top_margin = 20
right_margin = 20
bottom_margin = 20
left_margin = 20

body_width = 400

body_left_margin = (page_width - body_width - left_margin - right_margin) / 2

prawn_document(margin: [top_margin, right_margin, bottom_margin, left_margin], page_size: page_size) do |pdf|
  pdf.font_families.update('marianne' => {
    normal: Rails.root.join('lib/prawn/fonts/marianne/marianne-regular.ttf'),
    bold: Rails.root.join('lib/prawn/fonts/marianne/marianne-bold.ttf')
  })
  pdf.font 'marianne'

  grey = '555555'
  black = '333333'

  pdf.pad_bottom(30) do
    pdf.image DOSSIER_PDF_EXPORT_LOGO_SRC, width: 300, position: :center

    pdf.pad_top(15) do
      pdf.fill_color grey
      pdf.text t('.receipt'), size: 14, align: :center
    end
  end

  pdf.bounding_box([body_left_margin, pdf.cursor - 20], width: body_width) do
    pdf.fill_color black
    pdf.pad_top(40) { pdf.text @dossier.procedure.libelle, size: 14, character_spacing: -0.2, align: :center }

    pdf.fill_color grey
    description = t('.description', user_name: papertrail_requester_identity(@dossier), procedure: @dossier.procedure.libelle, date: l(@dossier.depose_at, format: '%e %B %Y'))
    pdf.pad_top(30) { pdf.text description, size: 10, character_spacing: -0.2, align: :left }

    pdf.fill_color black
    pdf.pad_top(30) { pdf.text t('views.shared.dossiers.demande.requester_identity'), size: 14, character_spacing: -0.2, align: :justify }

    if @dossier.individual.present?
      pdf.pad_top(7) do
        pdf.fill_color grey
        pdf.text "#{Individual.human_attribute_name(:prenom)} : #{@dossier.individual.prenom}", size: 10, character_spacing: -0.2, align: :justify
        pdf.text "#{Individual.human_attribute_name(:nom)} :  #{@dossier.individual.nom.upcase}", size: 10, character_spacing: -0.2, align: :justify
        pdf.text "#{User.human_attribute_name(:email)} :  #{@dossier.user.email}", size: 10, character_spacing: -0.2, align: :justify
      end
    end

    if @dossier.etablissement.present?
      pdf.pad_top(7) do
        pdf.fill_color grey
        pdf.text "Dénomination : " + raison_sociale_or_name(@dossier.etablissement), size: 10, character_spacing: -0.2, align: :justify
        pdf.text "SIRET : " + @dossier.etablissement.siret, size: 10, character_spacing: -0.2, align: :justify
        pdf.text "#{User.human_attribute_name(:email)} :  #{@dossier.user.email}", size: 10, character_spacing: -0.2, align: :justify
      end
    end

    pdf.fill_color black
    pdf.pad_top(30) { pdf.text Dossier.model_name.human, size: 14, character_spacing: -0.2, align: :justify }

    pdf.fill_color grey
    pdf.pad_top(7) do
      pdf.text "#{Dossier.human_attribute_name(:id)} : #{@dossier.id}", size: 10, character_spacing: -0.2, align: :justify
      pdf.text t('.file_submitted_at') + ' : ' + l(@dossier.depose_at, format: '%e %B %Y'), size: 10, character_spacing: -0.2, align: :justify
      pdf.text t('.dossier_state') + ' : ' + papertrail_dossier_state(@dossier), size: 10, character_spacing: -0.2, align: :justify
    end

    service = @dossier.procedure.service
    if service.present?
      pdf.fill_color black
      pdf.pad_top(30) { pdf.text t('.administrative_service'), size: 14, character_spacing: -0.2, align: :justify }

      pdf.fill_color grey
      pdf.pad_top(7) do
        pdf.text "#{Service.model_name.human} : " + [service.nom, service.organisme].join(", "), size: 10, character_spacing: -0.2, align: :justify
        pdf.text "#{Service.human_attribute_name(:adresse)} : #{service.adresse}", size: 10, character_spacing: -0.2, align: :justify
        pdf.text "#{Service.human_attribute_name(:email)} : #{service.email}", size: 10, character_spacing: -0.2, align: :justify
        if service.telephone.present?
          pdf.text "#{Service.human_attribute_name(:telephone)} : #{service.telephone}", size: 10, character_spacing: -0.2, align: :justify
        end
      end
    end

    pdf.fill_color black
    pdf.pad_top(100) do
      pdf.text t('.generated_at', date: l(Time.zone.now.to_date, format: :long)), size: 10, character_spacing: -0.2, align: :right
      pdf.text t('.signature', app_name: APPLICATION_NAME), size: 10, character_spacing: -0.2, align: :right
    end
  end
end
