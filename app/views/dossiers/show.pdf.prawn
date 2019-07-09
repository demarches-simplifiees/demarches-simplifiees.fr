require 'prawn/measurement_extensions'

def format_in_2_lines(pdf, label, text)
  pdf.text label
  pdf.text text
  pdf.text "\n"
end

def format_in_2_columns(pdf, label, text)
  pdf.text_box label, width: 200, height: 100, overflow: :expand, at: [0, pdf.cursor]
  pdf.text_box ":", width: 10, height: 100, overflow: :expand, at: [100, pdf.cursor]
  pdf.text_box text, width: 420, height: 100, overflow: :expand, at: [110, pdf.cursor]
  pdf.text "\n"
end

prawn_document(page_size: "A4") do |pdf|

  pdf.font_families.update( 'liberation serif' => { 
    normal: Rails.root.join('lib/prawn/fonts/liberation_serif/LiberationSerif-Regular.ttf' ),
    bold: Rails.root.join('lib/prawn/fonts/liberation_serif/LiberationSerif-Bold.ttf' ),
  })
  pdf.font 'liberation serif'

  pdf.svg IO.read("app/assets/images/header/logo-ds-wide.svg"), width: 300, position: :center
  pdf.move_down(40)

  pdf.text "Dossier Nº #{@dossier.id} déposé sur la démarche #{@dossier.procedure.libelle}"
  pdf.text "\n"

  entete = "Ce dossier a été <b>#{dossier_display_state(@dossier, lower: true)} le #{l(@dossier.processed_at.to_date)}</b>"
  if @dossier.motivation.present?
    entete += " avec la motivation suivante : #{@dossier.motivation}"
  end

  pdf.text entete, inline_format: true
  pdf.text "\n"

  pdf.font 'liberation serif', style: :bold do
    pdf.text "Identité du demandeur"
  end

  if @dossier.individual.present?
    format_in_2_columns(pdf, "Civilité", @dossier.individual.gender)
    format_in_2_columns(pdf, "Nom", @dossier.individual.nom)
    format_in_2_columns(pdf, "Prénom", @dossier.individual.prenom)

    if @dossier.individual.birthdate.present?
      format_in_2_columns(pdf, "Date de naissance", try_format_date(@dossier.individual.birthdate))
    end
  end
  pdf.text "\n"

  pdf.font 'liberation serif', style: :bold do
    pdf.text "Partie usager"
  end

  @dossier.champs.each do |champ|
    if champ.type != 'Champs::RepetitionChamp'
      format_in_2_lines(pdf, champ.libelle, champ.for_api.to_s)
    else
      champ.rows.each do |row|
        row.each do |inner_champ|
          format_in_2_lines(pdf, inner_champ.libelle, inner_champ.for_api.to_s)
        end
      end
    end
  end
end
