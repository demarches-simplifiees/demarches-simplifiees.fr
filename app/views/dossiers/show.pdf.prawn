require 'prawn/measurement_extensions'
require 'open-uri'
require 'rgeo'
require 'rgeo/geo_json'

def default_margin
  10
end

def maybe_start_new_page(pdf, size)
  if pdf.cursor < size + default_margin
    pdf.start_new_page
  end
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

def format_in_2_lines(pdf, label, text)
  min_height = [
    label.present? ? pdf.height_of_formatted([{ text: label, style: :bold, size: 12 }]) : nil,
    text.present? ? pdf.height_of_formatted([{ text: text }]) : nil
  ].compact.sum
  maybe_start_new_page(pdf, min_height)

  pdf.pad_bottom(2) do
    pdf.font 'marianne', style: :bold, size: 12  do
      pdf.text label
    end
  end
  pdf.pad_bottom(default_margin) do
    pdf.text text
  end
end

def format_in_2_columns(pdf, label, text)
  min_height = [
    label.present? ? pdf.height_of_formatted([{ text: label }]) : nil,
    text.present? ? pdf.height_of_formatted([{ text: text }]) : nil
  ].compact.max
  maybe_start_new_page(pdf, min_height)

  pdf.pad_bottom(default_margin) do
    height = [
      text_box(pdf, label, 0, 150),
      text_box(pdf, ':', 150, 10),
      text_box(pdf, text, 160, pdf.bounds.width - 160)
    ].max
    pdf.move_down height
  end
end

def add_title(pdf, title)
  maybe_start_new_page(pdf, 100)

  pdf.pad(default_margin) do
    pdf.font 'marianne', style: :bold, size: 20 do
      pdf.text title
    end
  end
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
    format_in_2_columns(pdf, "SIRET du siège social", etablissement.entreprise.siret_siege_social) if etablissement.entreprise.siret_siege_social.present?
    format_in_2_columns(pdf, "Dénomination", raison_sociale_or_name(etablissement))
    format_in_2_columns(pdf, "Forme juridique ", etablissement.entreprise_forme_juridique)

    if etablissement.entreprise_capital_social.present?
      format_in_2_columns(pdf, "Capital social ", pretty_currency(etablissement.entreprise_capital_social))
    end

    format_in_2_columns(pdf, "Libellé NAF ", etablissement.libelle_naf)
    format_in_2_columns(pdf, "Code NAF ", etablissement.naf)
    format_in_2_columns(pdf, "Date de création ", try_format_date(etablissement.entreprise.date_creation))

    if @include_infos_administration
      if etablissement.entreprise_effectif_mensuel.present?
        format_in_2_columns(pdf, "Effectif mensuel #{try_format_mois_effectif(etablissement)} (URSSAF) ", number_with_delimiter(etablissement.entreprise_effectif_mensuel.to_s))
      end
      if etablissement.entreprise_effectif_annuel_annee.present?
        format_in_2_columns(pdf, "Effectif moyen annuel #{etablissement.entreprise_effectif_annuel_annee} (URSSAF) ", number_with_delimiter(etablissement.entreprise_effectif_annuel.to_s))
      end
    end

    format_in_2_columns(pdf, "Effectif (ISPF) ", effectif(etablissement))
    format_in_2_columns(pdf, "Code effectif ", etablissement.entreprise.code_effectif_entreprise)
    if etablissement.entreprise.numero_tva_intracommunautaire.present?
      format_in_2_columns(pdf, "Numéro de TVA intracommunautaire ", etablissement.entreprise.numero_tva_intracommunautaire)
    end
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
end

def add_single_champ(pdf, champ)
  case champ.type
  when 'Champs::PieceJustificativeChamp', 'Champs::TitreIdentiteChamp'
    return
  when 'Champs::HeaderSectionChamp'
    add_section_title(pdf, champ.libelle)
  when 'Champs::ExplicationChamp'
    format_in_2_lines(pdf, champ.libelle, champ.description)
  when 'Champs::CarteChamp'
    geojson = champ.to_feature_collection.to_json
    format_in_2_lines(pdf, champ.libelle, geojson)
    draw_map(pdf, geojson)
  when 'Champs::SiretChamp'
    pdf.font 'marianne', style: :bold do
      pdf.text champ.libelle
    end
    if champ.etablissement.present?
      add_identite_etablissement(pdf, champ.etablissement)
    end
  when 'Champs::NumberChamp'
    value = champ.to_s.empty? ? 'Non communiqué' : number_with_delimiter(champ.to_s)
    format_in_2_lines(pdf, champ.libelle, value)
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
          add_single_champ(pdf, inner_champ)
        end
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
    ActionView::Base.full_sanitizer.sanitize(message.body))
end

def add_avis(pdf, avis)
  format_in_2_lines(pdf, "Avis de #{avis.email_to_display}#{avis.confidentiel? ? ' (confidentiel)' : ''}",
    avis.answer || 'En attente de réponse')
end

def add_etat_dossier(pdf, dossier)
  pdf.pad_bottom(default_margin) do
    pdf.text "Ce dossier est <b>#{dossier_display_state(dossier, lower: true)}</b>.", inline_format: true
  end
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
end

def draw_map(pdf, geojson)
  # For now, only support squares
  render_width=400
  render_height=400
  maybe_start_new_page(pdf, render_height)

  # GeoJSON expresses everything in EPSG:4326
  geo_factory = RGeo::Geographic.spherical_factory(srid: 4326)
  geojson = RGeo::GeoJSON.decode(geojson)

  # Compute bounding box and make it square
  bbox = RGeo::Cartesian::BoundingBox.new(geo_factory)
  geojson.each { |f| bbox.add(f.geometry) }
  center = geo_factory.point(bbox.center_x, bbox.center_y)
  bbox.add center.buffer(0.8 * bbox.max_point.distance(bbox.min_point))

  urls = [
    "wxs.ign.fr/ortho/geoportail/r/wms?LAYERS=ORTHOIMAGERY.ORTHOPHOTOS.BDORTHO",
    "wxs.ign.fr/administratif/geoportail/r/wms?LAYERS=ADMINEXPRESS_COG_2020",
    "wxs.ign.fr/parcellaire/geoportail/r/wms?LAYERS=CADASTRALPARCELS.PARCELLAIRE_EXPRESS",
  ]
  request = "EXCEPTIONS=text/xml&FORMAT=image/png&SERVICE=WMS&VERSION=1.3.0&REQUEST=GetMap&STYLES=&CRS=EPSG:4326&BBOX=#{bbox.min_y},#{bbox.min_x},#{bbox.max_y},#{bbox.max_x}&WIDTH=#{2*render_width}&HEIGHT=#{2*render_height}"

  def pos(bbox, point, render_width, render_height)
    w = bbox.x_span
    h = bbox.y_span
    [(point.x-bbox.min_x)/w*render_width, render_height + (point.y-bbox.max_y)/h*render_height]
  end

  pdf.bounding_box(
    [pdf.bounds.width/2 - render_width/2, pdf.cursor],
    width: render_width,
    height: render_height,
  ) do
    pdf.save_graphics_state do
      urls.each do |u|
        pdf.image URI.open("http://#{u}&#{request}"), :at => [0, render_height], :width => render_width, :height => render_height
      end
      pdf.line_width=2

      pdf.transparent(0.5, 1.0) do
        geojson.each do |f|
          g = f.geometry
          case g
          when RGeo::Feature::Point
            pdf.stroke_color 'EC3323'
            pdf.fill_color 'EC3323'

            pdf.fill_and_stroke_circle pos(bbox, g, render_width, render_height), 2
          when RGeo::Feature::LineString
            pdf.stroke_color '372A7F'
            pdf.fill_color '372A7F'

            vertices = g.points.map { |p| pos(bbox, p, render_width, render_height) }
            vertices.each_cons(2).each do |v|
              pdf.stroke_line v
            end
          when RGeo::Feature::Polygon
            pdf.stroke_color 'EC3323'
            pdf.fill_color 'EC3323'

            vertices = g.exterior_ring.points.map { |p| pos(bbox, p, render_width, render_height) }
            pdf.fill_and_stroke_polygon *vertices
          end
        end
      end
    end
  end

  def dms(decimal, positive, negative)
    sign = decimal >= 0
    decimal = decimal.abs
    ret = "#{decimal.floor()}°"
    decimal = 60 * decimal.modulo(1)
    ret = ret + "#{decimal.floor()}'"
    decimal = 60 * decimal.modulo(1)
    ret = ret + "#{decimal.floor()}\""
    if sign
      ret + positive
    else
      ret + negative
    end
  end
  geojson.each do |f|
    g = f.geometry
    d = case g
    when RGeo::Feature::Point
      "Un point à #{dms(g.y, 'N', 'S')} #{dms(g.x, 'E', 'W')}\n"
    when RGeo::Feature::LineString
      g = g.convex_hull.centroid
      "Une ligne autour de #{dms(g.y, 'N', 'S')} #{dms(g.x, 'E', 'W')}\n"
    when RGeo::Feature::Polygon
      g = g.centroid
      "Une aire autour de #{dms(g.y, 'N', 'S')} #{dms(g.x, 'E', 'W')}\n"
    end
    format_in_2_columns(pdf, d, f['description'])
  end
end

prawn_document(page_size: "A4") do |pdf|
  pdf.font_families.update( 'marianne' => {
    normal: Rails.root.join('lib/prawn/fonts/marianne/marianne-regular.ttf' ),
    bold: Rails.root.join('lib/prawn/fonts/marianne/marianne-bold.ttf' ),
  })
  pdf.font 'marianne'

  pdf.pad_bottom(40) do
    pdf.svg IO.read(DOSSIER_PDF_EXPORT_LOGO_SRC), width: 300, position: :center
  end

  format_in_2_columns(pdf, 'Dossier Nº', @dossier.id.to_s)
  format_in_2_columns(pdf, 'Démarche', @dossier.procedure.libelle)
  format_in_2_columns(pdf, 'Organisme', @dossier.procedure.organisation_name)

  add_etat_dossier(pdf, @dossier)

  if @dossier.motivation.present?
    format_in_2_columns(pdf, "Motif de la décision", @dossier.motivation)
  end
  add_title(pdf, 'Historique')
  add_etats_dossier(pdf, @dossier)

  add_title(pdf, "Identité du demandeur")

  if @dossier.france_connect_information.present?
    format_in_2_columns(pdf, 'Informations France Connect', "Le dossier a été déposé par le compte de #{@dossier.france_connect_information.given_name} #{@dossier.france_connect_information.family_name}, authentifié par France Connect le #{@dossier.france_connect_information.updated_at.strftime('%d/%m/%Y')}")
  end

  format_in_2_columns(pdf, "Email", @dossier.user_email_for(:display))

  if @dossier.individual.present?
    add_identite_individual(pdf, @dossier.individual)
  elsif @dossier.etablissement.present?
    add_identite_etablissement(pdf, @dossier.etablissement)
  end

  add_title(pdf, 'Formulaire')
  add_champs(pdf, @dossier.champs)

  if @include_infos_administration && @dossier.champs_private.present?
    add_title(pdf, "Annotations privées")
    add_champs(pdf, @dossier.champs_private)
  end

  if @include_infos_administration && @dossier.avis.present?
    add_title(pdf, "Avis")
    @dossier.avis.each do |avis|
      add_avis(pdf, avis)
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
