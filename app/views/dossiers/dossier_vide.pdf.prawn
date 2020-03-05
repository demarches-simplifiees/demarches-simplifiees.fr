require 'prawn/measurement_extensions'

def render_in_2_columns(pdf, label, text)
  pdf.text_box label, width: 200, height: 100, overflow: :expand, at: [0, pdf.cursor]
  pdf.text_box ":", width: 10, height: 100, overflow: :expand, at: [100, pdf.cursor]
  pdf.text_box text, width: 420, height: 100, overflow: :expand, at: [110, pdf.cursor]
  pdf.text "\n"
end

def format_in_2_lines(pdf, label, nb_lines = 1)
  add_single_line(pdf, label, 12, :bold)

  height = 10 * (nb_lines+1)
  pdf.bounding_box([0, pdf.cursor],:width => 460,:height => height) do
    pdf.stroke_bounds
  end
  pdf.text "\n"
end

def format_in_2_columns(pdf, label)
  pdf.text_box label, width: 200, height: 100, overflow: :expand, at: [0, pdf.cursor]
  pdf.bounding_box([110, pdf.cursor+5],:width => 350,:height => 20) do
    pdf.stroke_bounds
  end

  pdf.text "\n"
end

def format_with_checkbox(pdf, label, offset = 0)
  pdf.font 'liberation serif', size: 12 do
    pdf.stroke_rectangle [0 + offset, pdf.cursor], 10, 10
    pdf.text_box label, at: [15 + offset, pdf.cursor]
  end
  pdf.text "\n"
end

def add_page_numbering(pdf)
  # This method should be called at the end of the drawing since pages drawn after
  # do not have page numbering
  string = '<page> / <total>'
  options = {
      at: [0, -15],
      align: :right
  }
  pdf.number_pages string, options
end

def add_procedure(pdf, dossier)
  pdf.repeat(lambda {|page| page > 1 })  do
    pdf.draw_text dossier.procedure.libelle, :at => pdf.bounds.top_left
  end
end

def format_date(date)
  I18n.l(date, format: :message_date_with_year)
end

def add_identite_individual(pdf, dossier)
  format_in_2_columns(pdf, "Civilité")
  format_in_2_columns(pdf, "Nom")
  format_in_2_columns(pdf, "Prénom")
  format_in_2_columns(pdf, "Date de naissance")
end

def add_identite_etablissement(pdf, libelle)
  add_single_line(pdf, libelle, 12, :bold)

  format_in_2_columns(pdf, "SIRET")
  format_in_2_columns(pdf, "Dénomination")
  format_in_2_columns(pdf, "Forme juridique")
end

def add_single_line(pdf, libelle, size, style)
  pdf.font 'liberation serif', style: style, size: size do
    pdf.text libelle
  end
end

def add_title(pdf, title)
  add_single_line(pdf, title, 24, :bold)
  pdf.text "\n"
end

def add_libelle(pdf, champ)
  add_single_line(pdf, champ.libelle, 12, :bold)
end

def add_explanation(pdf, explanation)
  add_single_line(pdf, explanation, 9, :italic)
end

def render_single_champ(pdf, champ)
  case champ.type
  when 'Champs::RepetitionChamp'
    raise 'There should not be a RepetitionChamp here !'
  when 'Champs::PieceJustificativeChamp'
    add_single_line(pdf, 'Pièce justificative à joindre', 12, :bold)
    pdf.text champ.libelle
    pdf.text champ.description
    pdf.text "\n"
  when 'Champs::YesNoChamp', 'Champs::CheckboxChamp'
    add_libelle(pdf, champ)
    add_explanation(pdf, 'Cochez la mention applicable')
    format_with_checkbox(pdf, 'Oui')
    format_with_checkbox(pdf, 'Non')
    pdf.text "\n"
  when 'Champs::CiviliteChamp'
    add_libelle(pdf, champ)
    format_with_checkbox(pdf, Individual::GENDER_FEMALE)
    format_with_checkbox(pdf, Individual::GENDER_MALE)
    pdf.text "\n"
  when 'Champs::HeaderSectionChamp'
    add_single_line(pdf, champ.libelle, 18, :bold)
    pdf.text "\n"
  when 'Champs::ExplicationChamp'
    add_libelle(pdf, champ)
    pdf.text champ.description
    pdf.text "\n"
  when 'Champs::AddressChamp',  'Champs::CarteChamp', 'Champs::TextareaChamp'
    format_in_2_lines(pdf, champ.libelle, 3)
  when 'Champs::DropDownListChamp'
    add_libelle(pdf, champ)
    add_explanation(pdf, 'Cochez la mention applicable, une seule valeur possible')
    champ.drop_down_list.options.reject(&:blank?).each do |option|
      format_with_checkbox(pdf, option)
    end
    pdf.text "\n"
  when 'Champs::MultipleDropDownListChamp'
    add_libelle(pdf, champ)
    add_explanation(pdf, 'Cochez la mention applicable, plusieurs valeurs possibles')
    champ.drop_down_list.options.reject(&:blank?).each do |option|
      format_with_checkbox(pdf, option)
    end
    pdf.text "\n"
  when 'Champs::LinkedDropDownListChamp'
    add_libelle(pdf, champ)
    champ.primary_options.reject(&:blank?).each do |o|
      format_with_checkbox(pdf, o)
      champ.secondary_options[o].reject(&:blank?).each do |secondary_option|
        format_with_checkbox(pdf, secondary_option, 15)
      end
    end
    pdf.text "\n"
  when 'Champs::SiretChamp'
    add_identite_etablissement(pdf, champ.libelle)
  else
    format_in_2_lines(pdf, champ.libelle)
  end
end

def add_champs(pdf, champs)
  champs.each do |champ|
    if champ.type == 'Champs::RepetitionChamp'
      add_libelle(pdf, champ)
      (1..3).each do
        champ.rows.each do |row|
          row.each do |inner_champ|
            render_single_champ(pdf, inner_champ)
          end
        end
      end
    else
      render_single_champ(pdf, champ)
    end
  end
end

prawn_document(page_size: "A4") do |pdf|
  pdf.font_families.update( 'liberation serif' => {
      normal: Rails.root.join('lib/prawn/fonts/liberation_serif/LiberationSerif-Regular.ttf' ),
      bold: Rails.root.join('lib/prawn/fonts/liberation_serif/LiberationSerif-Bold.ttf' ),
      italic: Rails.root.join('lib/prawn/fonts/liberation_serif/LiberationSerif-Italic.ttf' ),
  })
  pdf.font 'liberation serif'
  pdf.svg IO.read("app/assets/images/header/logo-ds-wide.svg"), width: 300, position: :center
  pdf.move_down(40)

  render_in_2_columns(pdf, 'Démarche', @dossier.procedure.libelle)
  render_in_2_columns(pdf, 'Organisme', @dossier.procedure.organisation_name)
  pdf.text "\n"

  add_title(pdf, "Identité du demandeur")

  format_in_2_columns(pdf, "Email")
  if @dossier.procedure.for_individual?
    add_identite_individual(pdf, @dossier)
  else
    render_identite_etablissement(pdf, @dossier.etablissement) if @dossier.etablissement.present?
  end
  pdf.text "\n"

  add_title(pdf, 'Formulaire')
  add_champs(pdf, @dossier.champs)
  add_page_numbering(pdf)
  add_procedure(pdf, @dossier)
end
