require 'prawn/measurement_extensions'

def default_margin
  10
end

def maybe_start_new_page(pdf, size)
  if pdf.cursor < size + default_margin
    pdf.start_new_page
  end
end

def clean_string(str)
  str&.each_line { _1.gsub(/[[:space:]]/, ' ') } # replace non breaking space, which are invalid in pdf
end

def text_box(pdf, text, x, width)
  box = ::Prawn::Text::Box.new(text.to_s,
    document: pdf,
    width: width,
    overflow: :expand,
    at: [x, pdf.cursor])

  box.render
  box.height
end

def prawn_text(message)
  tags = ['a', 'b', 'br', 'color', 'font', 'i', 'strong', 'sub', 'sup', 'u']
  atts = ['alt', 'character_spacing', 'href', 'name', 'rel', 'rgb', 'size', 'src', 'target']
  ActionView::Base.safe_list_sanitizer.sanitize(message.to_s, tags: tags, attributes: atts)
end

def format_in_2_lines(pdf, label, text)
  text = prawn_text(text)
  min_height = [
    label.present? ? pdf.height_of_formatted([{ text: label, style: :bold, size: 12 }]) : nil,
    text.present? ? pdf.height_of_formatted([{ text: text, size: 9, inline_format: true }]) : nil
  ].compact.sum
  maybe_start_new_page(pdf, min_height)

  pdf.pad_bottom(2) do
    pdf.font 'marianne', style: :bold, size: 12 do
      pdf.text label
    end
  end
  pdf.pad_bottom(default_margin) do
    pdf.text prawn_text(text), size: 9, inline_format: true
    pdf.text "\n", size: 9
  end
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
  maybe_start_new_page(pdf, 100)

  pdf.pad(default_margin) do
    pdf.fill_color "E11619"
    pdf.font 'marianne', style: :bold, size: 16 do
      pdf.text title
    end
    pdf.fill_color "000000"
  end
  pdf.text "\n"
end

def add_section_title(pdf, title)
  maybe_start_new_page(pdf, 100)

  pdf.pad_bottom(default_margin) do
    pdf.font 'marianne', style: :bold, size: 14 do
      pdf.text title
    end
  end
end

def add_identite_individual(pdf, individual)
  pdf.pad_bottom(default_margin) do
    format_in_2_columns(pdf, "Civilité", individual.gender)
    format_in_2_columns(pdf, "Nom", individual.nom)
    format_in_2_columns(pdf, "Prénom", individual.prenom)

    if individual.birthdate.present?
      format_in_2_columns(pdf, "Date de naissance", try_format_date(individual.birthdate))
    end
  end
end

def add_identite_etablissement(pdf, etablissement)
  pdf.pad_bottom(default_margin) do
    format_in_2_columns(pdf, "SIRET", etablissement.siret)
    format_in_2_columns(pdf, "SIRET du siège social", etablissement.entreprise.siret_siege_social) if etablissement.entreprise.siret_siege_social.present?
    format_in_2_columns(pdf, "Dénomination", raison_sociale_or_name(etablissement))
    format_in_2_columns(pdf, "Forme juridique ", etablissement.entreprise_forme_juridique)

    if etablissement.entreprise_capital_social.present?
      format_in_2_columns(pdf, "Capital social ", pretty_currency(etablissement.entreprise_capital_social))
    end

    format_in_2_columns(pdf, "Libellé NAF ", etablissement.libelle_naf)
    format_in_2_columns(pdf, "Code NAF ", etablissement.naf)
    format_in_2_columns(pdf, "Date de création ", try_format_date(etablissement.entreprise.date_creation))

    if etablissement.entreprise_etat_administratif.present?
      format_in_2_columns(pdf, "État administratif", humanized_entreprise_etat_administratif(etablissement))
    end

    if @acls[:include_infos_administration]
      if etablissement.entreprise_effectif_mensuel.present?
        format_in_2_columns(pdf, "Effectif mensuel #{try_format_mois_effectif(etablissement)} de l'établissement (URSSAF ou MSA) ", number_with_delimiter(etablissement.entreprise_effectif_mensuel.to_s))
      end
      if etablissement.entreprise_effectif_annuel_annee.present?
        format_in_2_columns(pdf, "Effectif moyen annuel #{etablissement.entreprise_effectif_annuel_annee} de l'unité légale (URSSAF ou MSA) ", number_with_delimiter(etablissement.entreprise_effectif_annuel.to_s))
      end
    end

    format_in_2_columns(pdf, "Effectif (ISPF) ", effectif(etablissement))
    format_in_2_columns(pdf, "Code effectif ", etablissement.entreprise.code_effectif_entreprise)
    if etablissement.entreprise.numero_tva_intracommunautaire.present?
      format_in_2_columns(pdf, "Numéro de TVA intracommunautaire ", etablissement.entreprise.numero_tva_intracommunautaire)
    end
    format_in_2_columns(pdf, "Adresse ", etablissement.adresse)

    if etablissement.association?
      format_in_2_columns(pdf, "Numéro RNA ", etablissement.association_rna)
      format_in_2_columns(pdf, "Titre ", etablissement.association_titre)
      format_in_2_columns(pdf, "Objet ", etablissement.association_objet)
      format_in_2_columns(pdf, "Date de création ", try_format_date(etablissement.association_date_creation))
      format_in_2_columns(pdf, "Date de publication ", try_format_date(etablissement.association_date_publication))
      format_in_2_columns(pdf, "Date de déclaration ", try_format_date(etablissement.association_date_declaration))
    end
  end
end

def add_single_champ(pdf, champ)
  tdc = champ.type_de_champ
  return if champ.conditional? && !champ.visible?

  case champ.type
  when 'Champs::PieceJustificativeChamp', 'Champs::TitreIdentiteChamp'
    return
  when 'Champs::HeaderSectionChamp'
    libelle = if @dossier.auto_numbering_section_headers_for?(champ)
      "#{@dossier.index_for_section_header(champ)}. #{champ.libelle}"
    else
      champ.libelle
    end

    add_section_title(pdf, libelle)
  when 'Champs::ExplicationChamp'
    format_in_2_lines(pdf, tdc.libelle, strip_tags(tdc.description))
  when 'Champs::CarteChamp'
    pdf.pad_bottom(4) do
      pdf.font 'marianne', style: :bold, size: 12 do
        pdf.text tdc.libelle
      end

      pdf.indent(default_margin) do
        champ.geo_areas.each do |area|
          pdf.text "- #{clean_string(area.label)}"
        end
      end
    end
  when 'Champs::SiretChamp'
    pdf.font 'marianne', style: :bold do
      pdf.text tdc.libelle
    end
    if champ.etablissement.present?
      add_identite_etablissement(pdf, champ.etablissement)
    end
  when 'Champs::NumberChamp'
    value = champ.blank? ? 'Non communiqué' : number_with_delimiter(champ.to_s)
    format_in_2_lines(pdf, tdc.libelle, value)
  when 'Champs::AddressChamp'
    value = champ.blank? ? 'Non communiqué' : champ.to_s
    format_in_2_lines(pdf, tdc.libelle, value)
    if champ.full_address?
      format_in_2_lines(pdf, "Code INSEE :", champ.commune&.fetch(:code))
      format_in_2_lines(pdf, "Code Postal :", champ.commune&.fetch(:postal_code))
      format_in_2_lines(pdf, "Département :", champ.departement_code_and_name)
    end
  when 'Champs::CommuneChamp'
    value = champ.blank? ? 'Non communiqué' : champ.to_s
    format_in_2_lines(pdf, tdc.libelle, value)
    format_in_2_lines(pdf, "Code Postal :", champ.code_postal) if champ.code_postal?
    format_in_2_lines(pdf, "Département :", champ.departement_code_and_name) if champ.departement?
  when 'Champs::TextareaChamp'
    value = champ.blank? ? 'Non communiqué' : champ.to_s
    format_in_2_lines(pdf, tdc.libelle, clean_string(value))
  else
    value = champ.blank? ? 'Non communiqué' : champ.to_s
    format_in_2_columns(pdf, tdc.libelle, value)
  end
end

def add_champs(pdf, champs)
  champs.each do |champ|
    if champ.type == 'Champs::RepetitionChamp'
      add_section_title(pdf, champ.libelle)
      champ.rows.each do |row|
        row.each do |inner_champ|
          add_single_champ(pdf, inner_champ)
        end
        pdf.move_down(default_margin)
      end
    else
      add_single_champ(pdf, champ)
    end
  end
end

def add_message(pdf, message)
  sender = message.redacted_email
  if message.sent_by_system?
    sender = 'Email automatique'
  elsif message.sent_by?(@dossier.user)
    sender = @dossier.user_email_for(:display)
  end

  format_in_2_lines(pdf, "#{sender}, #{try_format_date(message.created_at)}",
    ActionView::Base.full_sanitizer.sanitize(clean_string(message.body)))
end

def add_avis(pdf, avis)
  title = "Avis demandé à #{avis.email_to_display}#{avis.confidentiel? ? ' (confidentiel)' : ''} :"

  message = "« #{avis.introduction} »"
  answer = avis.answer || 'En attente de réponse'

  binary_question = avis.question_label ? "« #{avis.question_label} »" : nil
  binary_answer = if binary_question.present?
    [true, false].include?(avis.question_answer) ? t("question_answer.#{avis.question_answer}", scope: 'helpers.label') : 'En attente de réponse'
  else
    nil
  end

  min_height = [
    pdf.height_of_formatted([{ text: title, style: :bold, size: 12 }]),

    pdf.height_of_formatted([{ text: message, size: 12 }]),
    pdf.height_of_formatted([{ text: answer, size: 12 }]),

    binary_question.present? ? pdf.height_of_formatted([{ text: binary_question, size: 12 }]) : nil,
    binary_answer.present? ? pdf.height_of_formatted([{ text: binary_answer, size: 12 }]) : nil
  ].compact.sum

  maybe_start_new_page(pdf, min_height)

  pdf.pad_bottom(default_margin) do
    pdf.pad_bottom(2) do
      pdf.font 'marianne', style: :bold, size: 12 do
        pdf.text title
      end
    end

    pdf.font 'marianne', size: 12 do
      pdf.text clean_string(message), color: "666666"
      pdf.text clean_string(answer)
    end

    if binary_question.present?
      pdf.pad_top(4) do
        pdf.font 'marianne', size: 12 do
          pdf.text clean_string(binary_question), color: "666666"
          pdf.text binary_answer
        end
      end
    end
  end
end

def add_etat_dossier(pdf, dossier)
  pdf.pad_bottom(default_margin) do
    pending_correction = dossier.pending_correction? ? " (en attente de correction)" : nil
    pdf.text "Ce dossier est <b>#{clean_string(dossier_display_state(dossier, lower: true))}#{pending_correction}</b>.", inline_format: true
  end
end

def add_etats_dossier(pdf, dossier)
  if dossier.depose_at.present?
    format_in_2_columns(pdf, "Déposé le", try_format_date(dossier.depose_at))
  end

  if dossier.pending_correction?
    format_in_2_columns(pdf, "Correction demandée le", try_format_date(dossier.pending_correction.created_at))
  end

  if dossier.en_instruction_at.present?
    format_in_2_columns(pdf, "En instruction le", try_format_date(dossier.en_instruction_at))
  end

  if dossier.sva_svr_decision_triggered_at.present?
    format_in_2_columns(pdf, "Décision #{dossier.procedure.sva_svr_configuration.human_decision} prise le", try_format_date(dossier.sva_svr_decision_triggered_at))
  elsif dossier.sva_svr_decision_on.present?
    value = if dossier.pending_correction?
      "#{dossier.sva_svr_decision_in_days} jours après la correction"
    else
      try_format_date(dossier.sva_svr_decision_on)
    end

    format_in_2_columns(pdf, "Date prévisionnelle #{dossier.procedure.sva_svr_configuration.human_decision}", value)
  end

  if dossier.processed_at.present?
    format_in_2_columns(pdf, "Décision le", try_format_date(dossier.processed_at))
  end
end

prawn_document(page_size: "A4") do |pdf|
  pdf.font_families.update('marianne' => {
    normal: Rails.root.join('lib/prawn/fonts/marianne/marianne-regular.ttf'),
    bold: Rails.root.join('lib/prawn/fonts/marianne/marianne-bold.ttf'),
    bold_italic: Rails.root.join('lib/prawn/fonts/marianne/marianne-bold.ttf'),
    italic: Rails.root.join('lib/prawn/fonts/marianne/marianne-bold.ttf')
  })
  pdf.font 'marianne'

  pdf.pad_bottom(40) do
    pdf.image DOSSIER_PDF_EXPORT_LOGO_SRC, width: 300, position: :center
  end

  pdf.move_down(40)

  format_in_2_columns(pdf, 'Dossier Nº', @dossier.id.to_s)
  format_in_2_columns(pdf, 'Démarche', @dossier.procedure.libelle)
  format_in_2_columns(pdf, 'Organisme', @dossier.procedure.organisation_name)

  add_etat_dossier(pdf, @dossier)

  if @dossier.motivation.present?
    format_in_2_columns(pdf, "Motif de la décision", clean_string(@dossier.motivation))
  end
  add_title(pdf, 'Historique')
  add_etats_dossier(pdf, @dossier)

  add_title(pdf, "Identité du demandeur")

  if @dossier.france_connect_information.present?
    format_in_2_columns(pdf, 'Informations FranceConnect', france_connect_informations(@dossier.france_connect_information, @dossier.user.loged_in_with_france_connect))
  end

  format_in_2_columns(pdf, "Email", @dossier.user_email_for(:display))

  if @dossier.individual.present?
    add_identite_individual(pdf, @dossier.individual)
  elsif @dossier.etablissement.present?
    add_identite_etablissement(pdf, @dossier.etablissement)
  end

  add_title(pdf, 'Formulaire')
  add_champs(pdf, @dossier.champs_public)

  if @acls[:include_infos_administration] && @dossier.champs_private.present?
    add_title(pdf, "Annotations privées")
    add_champs(pdf, @dossier.champs_private)
  end

  if @acls[:include_infos_administration] && @dossier.avis.present?
    add_title(pdf, "Avis")
    @dossier.avis.each do |avis|
      add_avis(pdf, avis)
    end
  end

  if @acls[:include_avis_for_expert] && @dossier.avis.present?
    add_title(pdf, "Avis")
    if @acls[:only_for_expert]
      @dossier.avis_for_expert(@acls[:only_for_expert]).each do |avis|
        add_avis(pdf, avis)
      end
    else
      @dossier.avis.each do |avis|
        add_avis(pdf, avis)
      end
    end
  end

  if @dossier.commentaires.present?
    add_title(pdf, 'Messagerie')
    @dossier.commentaires.each do |commentaire|
      add_message(pdf, commentaire)
    end
  end

  pdf.number_pages '<page> / <total>', at: [pdf.bounds.right - 80, pdf.bounds.bottom], align: :right, size: 10
end
