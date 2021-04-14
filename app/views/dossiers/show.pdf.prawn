require 'prawn/measurement_extensions'

def prawn_text(message)
  tags = ['a', 'b', 'br', 'color', 'font', 'i', 'strong', 'sub', 'sup', 'u']
  atts = ['alt', 'character_spacing', 'href', 'name', 'rel', 'rgb', 'size', 'src', 'target']
  text = ActionView::Base.safe_list_sanitizer.sanitize(message.to_s, tags: tags, attributes: atts)
end

def format_in_2_lines(pdf, label, text)
  pdf.font 'marianne', style: :bold, size: 10 do
    pdf.text label
  end
  pdf.text prawn_text(text), size: 9, inline_format: true
  pdf.text "\n", size: 9
end

def render_box(pdf, text, x, width)
  text = ::Prawn::Text::Formatted::Parser.format(prawn_text(text)) unless text.is_a? Array
  box = ::Prawn::Text::Formatted::Box.new(text, { document: pdf, size: 11, width: width, overflow: :expand, at: [x, pdf.cursor] })
  [box.render, box.height]
end

def format_in_2_columns(pdf, label, text)
  # enough space for label ?
  label = ::Prawn::Text::Formatted::Parser.format(label)
  box = ::Prawn::Text::Formatted::Box.new(label, { document: pdf, size: 11, width: 100, overflow: :expand, at: [0, pdf.cursor] })
  remaining = box.render(dry_run: true)
  pdf.start_new_page if remaining.present?
  while text.present?
    (_, h1) = render_box(pdf, label, 0, 100)
    (_, h2) = render_box(pdf, ':', 100, 10)
    (text, h3) = render_box(pdf, text, 110, pdf.bounds.width - 110)
    pdf.move_down 5 + [h1, h2, h3].max
    pdf.start_new_page if text.present?
  end
end

def add_title(pdf, title)
  title_style = { style: :bold, size: 16 }
  pdf.fill_color "E11619"
  pdf.font 'marianne', title_style do
    pdf.text title
  end
  pdf.text "\n"
  pdf.fill_color "000000"
end

def format_date(date)
  I18n.l(date, format: :message_date_with_year)
end

def add_identite_individual(pdf, dossier)
  format_in_2_columns(pdf, "Civilité", dossier.individual.gender)
  format_in_2_columns(pdf, "Nom", dossier.individual.nom)
  format_in_2_columns(pdf, "Prénom", dossier.individual.prenom)

  if dossier.individual.birthdate.present?
    format_in_2_columns(pdf, "Date de naissance", try_format_date(dossier.individual.birthdate))
  end
end

def render_siret_info(pdf, etablissement)
  pdf.text " - Dénomination : #{raison_sociale_or_name(etablissement)}"
  pdf.text " - Forme juridique : #{etablissement.entreprise_forme_juridique}"
  if etablissement.entreprise_capital_social.present?
    pdf.text " - Capital social : #{pretty_currency(etablissement.entreprise_capital_social)}"
  end
  pdf.text "\n"
end

def render_identite_etablissement(pdf, etablissement)
  format_in_2_columns(pdf, "Numéro TAHITI", etablissement.siret)
  format_in_2_columns(pdf, "Numéro TAHITI du siège social", etablissement.entreprise.siret_siege_social) if etablissement.entreprise.siret_siege_social.present?
  format_in_2_columns(pdf, "Dénomination", raison_sociale_or_name(etablissement))
  format_in_2_columns(pdf, "Forme juridique ", etablissement.entreprise_forme_juridique)
  if etablissement.entreprise_capital_social.present?
    format_in_2_columns(pdf, "Capital social ", pretty_currency(etablissement.entreprise_capital_social))
  end
  format_in_2_columns(pdf, "Libellé NAF ", etablissement.libelle_naf)
  format_in_2_columns(pdf, "Code NAF ", etablissement.naf)
  format_in_2_columns(pdf, "Date de création ", try_format_date(etablissement.entreprise.date_creation))
  if @include_infos_administration
    format_in_2_columns(pdf, "Effectif mensuel #{try_format_mois_effectif(etablissement)} (URSSAF) ", etablissement.entreprise_effectif_mensuel)
    format_in_2_columns(pdf, "Effectif moyen annuel #{etablissement.entreprise_effectif_annuel_annee} (URSSAF) ", etablissement.entreprise_effectif_annuel)
  end
  format_in_2_columns(pdf, "Effectif (ISPF) ", effectif(etablissement))
  format_in_2_columns(pdf, "Code effectif ", etablissement.entreprise.code_effectif_entreprise)
  format_in_2_columns(pdf, "Numéro de TVA intracommunautaire ", etablissement.entreprise.numero_tva_intracommunautaire) if etablissement.entreprise.numero_tva_intracommunautaire.present?
  format_in_2_columns(pdf, "Adresse ", etablissement.adresse)
  if etablissement.association?
    format_in_2_columns(pdf, "Numéro RNA ", etablissement.association_rna)
    format_in_2_columns(pdf, "Titre ", etablissement.association_titre)
    format_in_2_columns(pdf, "Objet ", etablissement.association_objet)
    format_in_2_columns(pdf, "Date de création ", try_format_date(etablissement.association_date_creation))
    format_in_2_columns(pdf, "Date de publication ", try_format_date(etablissement.association_date_publication))
    format_in_2_columns(pdf, "Date de déclaration ", try_format_date(etablissement.association_date_declaration))
  end
end

def render_single_champ(pdf, champ)
  case champ.type
  when 'Champs::RepetitionChamp'
    raise 'There should not be a RepetitionChamp here !'
  when 'Champs::PieceJustificativeChamp'
    url = Rails.application.routes.url_helpers.champs_piece_justificative_download_url({ champ_id: champ.id })
    link = if champ.piece_justificative_file.present?
      display = champ.piece_justificative_file.filename
      content_tag :a, display, { href: url, target: '_blank', rel: 'noopener' }
    else
      "Non renseigné"
    end
    format_in_2_columns(pdf, champ.libelle, link)
  when 'Champs::HeaderSectionChamp'
    pdf.font 'marianne', style: :bold, size: 14 do
      pdf.text champ.libelle
    end
    pdf.text "\n"
  when 'Champs::ExplicationChamp'
    format_in_2_columns(pdf, champ.libelle, champ.description)
  when 'Champs::CarteChamp'
    format_in_2_columns(pdf, champ.libelle, champ.to_feature_collection.to_json)
  when 'Champs::SiretChamp'
    pdf.font 'marianne', style: :bold, size: 9 do
      pdf.text champ.libelle
    end
    pdf.text " - Numéro TAHITI: #{champ.to_s}"
    render_identite_etablissement(pdf, champ.etablissement) if champ.etablissement.present?
    pdf.text "\n"
  when 'Champs::NumberChamp'
    value = number_with_delimiter(champ.to_s)
    format_in_2_columns(pdf, champ.libelle, value)
  else
    value = champ.to_s.empty? ? 'Non renseigné' : champ.for_tag
    format_in_2_columns(pdf, champ.libelle, value)
  end
end

def add_champs(pdf, champs)
  champs.each do |champ|
    if champ.type == 'Champs::RepetitionChamp'
      champ.rows.each do |row|
        row.each do |inner_champ|
          render_single_champ(pdf, inner_champ)
        end
      end
    else
      render_single_champ(pdf, champ)
    end
  end
end

def add_message(pdf, message)
  sender = message.redacted_email
  if message.sent_by_system?
    sender = 'Email automatique'
  elsif message.sent_by?(@dossier.user)
    sender = @dossier.user.email
  end

  pdf.text "#{sender}, #{format_date(message.created_at)}", style: :bold
  pdf.text prawn_text(message.body), size: 9, inline_format: true
  pdf.text "\n", size: 9
end

def add_avis(pdf, avis)
  pdf.text "Avis de #{avis.email_to_display}", style: :bold
  if avis.confidentiel?
    pdf.text "(confidentiel)", style: :bold
  end
  text = avis.answer || 'En attente de réponse'
  pdf.text prawn_text(text), inline_format: true
  pdf.text "\n"
end

def add_etats_dossier(pdf, dossier)
  if dossier.en_construction_at.present?
    format_in_2_columns(pdf, "Déposé le", try_format_date(dossier.en_construction_at))
  end
  if dossier.en_instruction_at.present?
    format_in_2_columns(pdf, "En instruction le", try_format_date(dossier.en_instruction_at))
  end
  if dossier.processed_at.present?
    format_in_2_columns(pdf, "Décision le", try_format_date(dossier.processed_at))
  end

  pdf.text "\n"
end

prawn_document(page_size: "A4") do |pdf|
  pdf.font_families.update('marianne' => {
    normal: Rails.root.join('lib/prawn/fonts/marianne/marianne-regular.ttf'),
    bold: Rails.root.join('lib/prawn/fonts/marianne/marianne-bold.ttf'),
    bold_italic: Rails.root.join('lib/prawn/fonts/marianne/marianne-bold.ttf'),
    italic: Rails.root.join('lib/prawn/fonts/marianne/marianne-bold.ttf'),
  })
  pdf.font 'marianne'

  pdf.bounding_box([0, pdf.cursor], :width => 523, :height => 40) do
    pdf.fill_color "E11619"
    pdf.fill_rectangle [0, 40], 523, 40
    pdf.svg IO.read(DOSSIER_PDF_EXPORT_LOGO_SRC), width: 300, position: :center, vposition: :center
    pdf.fill_color "000000"
  end

  pdf.move_down(40)

  format_in_2_columns(pdf, 'Dossier Nº', @dossier.id.to_s)
  format_in_2_columns(pdf, 'Démarche', @dossier.procedure.libelle)
  format_in_2_columns(pdf, 'Organisme', @dossier.procedure.organisation_name)
  pdf.text "\n"

  pdf.text "Ce dossier est <b>#{dossier_display_state(@dossier, lower: true)}</b>.", inline_format: true
  pdf.text "\n"
  if @dossier.motivation.present?
    format_in_2_columns(pdf, "Motif de la décision", @dossier.motivation)
  end
  add_title(pdf, 'Historique')
  add_etats_dossier(pdf, @dossier)

  add_title(pdf, "Identité du demandeur")

  if @dossier.france_connect_information.present?
    format_in_2_columns(pdf, 'Informations France Connect', "Le dossier a été déposé par le compte de #{@dossier.france_connect_information.given_name} #{@dossier.france_connect_information.family_name}, authentifié par France Connect le #{@dossier.france_connect_information.updated_at.strftime('%d/%m/%Y')}")
  end
  format_in_2_columns(pdf, "Email", @dossier.user.email)
  add_identite_individual(pdf, @dossier) if @dossier.individual.present?
  render_identite_etablissement(pdf, @dossier.etablissement) if @dossier.etablissement.present?
  pdf.text "\n"

  add_title(pdf, 'Formulaire')
  add_champs(pdf, @dossier.champs)

  if @include_infos_administration && @dossier.champs_private&.size > 0
    add_title(pdf, "Annotations privées")
    add_champs(pdf, @dossier.champs_private)
  end

  if @include_infos_administration && @dossier.avis.present?
    add_title(pdf, "Avis")
    @dossier.avis.each do |avis|
      add_avis(pdf, avis)
    end
  end

  add_title(pdf, 'Messagerie')
  @dossier.commentaires.each do |commentaire|
    add_message(pdf, commentaire)
  end
end
