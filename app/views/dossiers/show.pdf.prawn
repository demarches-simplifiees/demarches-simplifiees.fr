require 'prawn/measurement_extensions'

def format_in_2_lines(pdf, label, text)
  pdf.font 'liberation serif', style: :bold, size: 12 do
    pdf.text label
  end
  pdf.text text
  pdf.text "\n"
end

def format_in_2_columns(pdf, label, text)
  pdf.text_box label, width: 200, height: 100, overflow: :expand, at: [0, pdf.cursor]
      pdf.text_box ":", width: 10, height: 100, overflow: :expand, at: [100, pdf.cursor]
  pdf.text_box text, width: 420, height: 100, overflow: :expand, at: [110, pdf.cursor]
  pdf.text "\n"
end

def add_title(pdf, title)
  title_style = {style: :bold, size: 24}
  pdf.font 'liberation serif', title_style do
    pdf.text title
  end
end

def format_date(date)
  is_current_year = (date.year == Time.zone.today.year)
  template = is_current_year ? :message_date : :message_date_with_year
  I18n.l(date, format: template)
end

def render_single_champ(pdf, champ)
  case champ.type
  when 'Champs::RepetitionChamp'
    raise 'There should not be a RepetitionChamp here !'
  when 'Champs::PieceJustificativeChamp'
    return
  when 'Champs::HeaderSectionChamp'
    pdf.font 'liberation serif', style: :bold, size: 18 do
      pdf.text champ.libelle
    end
    pdf.text "\n"
  when 'Champs::CarteChamp'
    format_in_2_lines(pdf, champ.libelle, champ.geo_json.to_s)
  when 'Champs::SiretChamp'
    format_in_2_lines(pdf, champ.libelle, champ.to_s)
    if champ.etablissement.present?
      etablissement = champ.etablissement
      format_in_2_lines(pdf, champ.libelle, raison_sociale_or_name(etablissement))
    end
  else
    value = champ.to_s.empty? ? 'Non communiqué' : champ.to_s
    format_in_2_lines(pdf, champ.libelle, value)
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
  pdf.text ActionView::Base.full_sanitizer.sanitize(message.body)
  pdf.text "\n"
end

def add_avis(pdf, avis)
  pdf.text "Avis de #{avis.email_to_display}", style: :bold
  if avis.confidentiel?
    pdf.text "(confidentiel)", style: :bold
  end
  text = avis.answer || 'En attente de réponse'
  pdf.text text, style: :bold
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

  entete = "Ce dossier est <b>#{dossier_display_state(@dossier, lower: true)}</b>"
  if @dossier.motivation.present?
    entete += " avec la motivation suivante : #{@dossier.motivation}"
  end

  pdf.text entete, inline_format: true
  pdf.text "\n"

  add_title(pdf, "Identité du demandeur")

  if @dossier.individual.present?
    format_in_2_columns(pdf, "Civilité", @dossier.individual.gender)
    format_in_2_columns(pdf, "Nom", @dossier.individual.nom)
    format_in_2_columns(pdf, "Prénom", @dossier.individual.prenom)

    if @dossier.individual.birthdate.present?
      format_in_2_columns(pdf, "Date de naissance", try_format_date(@dossier.individual.birthdate))
    end
  end
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
  @dossier.commentaires.with_attached_piece_jointe.each do |commentaire|
    add_message(pdf, commentaire)
  end
end
