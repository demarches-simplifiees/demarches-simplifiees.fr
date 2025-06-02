# frozen_string_literal: true

require 'prawn/measurement_extensions'
require 'prawn/qrcode'

#----- A4 page size
page_size = 'A4'
# page_height = 842
page_width = 595

#----- margins
body_width = md_version == :v2 ? 450 : 400
top_margin = 50
bottom_margin = 20

right_margin = (page_width - body_width) / 2
left_margin = right_margin

#----- size of images
qrcode_size = 30.mm
max_signature_size = 40.mm
max_logo_height = 40.mm
max_logo_width = md_version == :v2 ? body_width - qrcode_size - 5.mm : body_width

def normalize_pdf_text(text)
  text&.tr("\t", '  ')
end

title = normalize_pdf_text(@attestation.fetch(:title))
body = normalize_pdf_text(@attestation.fetch(:body))
footer = normalize_pdf_text(@attestation.fetch(:footer))
created_at = @attestation.fetch(:created_at)

logo = @attestation[:logo]
signature = @attestation[:signature]
qrcode = @attestation[:qrcode]
footer_height = qrcode.present? && md_version == :v1 ? qrcode_size + 40 : 30

info = {
  :Title => title,
  :Subject => "Attestation pour un dossier",
  :Creator => (APPLICATION_NAME).to_s,
  :Producer => "Prawn",
  :CreationDate => created_at
}

def print_text(pdf, text, size)
  pdf.text prawn_text(text), size: size, character_spacing: -0.2, align: :justify, inline_format: true
end

def print_image(pdf, c)
  attachment = ActiveStorage::Attachment.find_by(id: c.attributes['id'].to_s)
  attachment.blob.open { |file| pdf.image file, fit: [30.mm, 40.mm], position: :center }
  # url = c.attributes['src']
  # display = c.attributes['display']
  # text = content_tag :a, display, { href: url, target: '_blank', rel: 'noopener' }
  # pdf.pad_top(5) { pdf.text text, size: 8, color: '000055', align: :center, inline_format: true }
end

def prawn_text(message)
  tags = ['a', 'b', 'br', 'color', 'font', 'i', 'strong', 'sub', 'sup', 'u']
  atts = ['alt', 'character_spacing', 'href', 'name', 'rel', 'rgb', 'size', 'src', 'target']
  message = message.gsub(/(<a[^>]*>)/, "\\1<color rgb='2d2bb3'><u>").gsub(/(<\/a>)/, "</u></color>\\1")
  ActionView::Base.safe_list_sanitizer.sanitize(message.to_s, tags: tags, attributes: atts)
end

def make_link(display, url)
  tag.a(tag.u(tag.color(display, rgb: "2d2bb3")), href: url, target: '_blank', rel: 'noopener')
end

def cell_link(pdf, display, url)
  ::Prawn::Table::Cell::Text.new(pdf, [], { content: make_link(display, url), inline_format: true, size: 8 })
end

def cell_image(pdf, c)
  url = c.attributes['src'].to_s
  display = c.attributes['display']&.to_s || c.children.to_s
  id = c.attributes['id']&.to_s
  if id && display
    attachment = ActiveStorage::Attachment.find_by(id: id)
    [
      attachment.blob.open { |file| ::Prawn::Table::Cell::Image.new(pdf, [], { image: file, fit: [20.mm, 20.mm], position: :center }) },
      cell_link(pdf, display, url)
    ]
  else
    ""
  end
end

def cell_text(pdf, c)
  ::Prawn::Table::Cell::Text.new(pdf, [], { content: prawn_text(c.to_s), inline_format: true, size: 10 })
end

def cell_values(pdf, cells)
  cells.children.chunk_while { |prev, curr| prev.name != 'img' && curr.name != 'img' }.flat_map do |chunk|
    if chunk.first.name == 'img'
      cell_image(pdf, chunk.first)
    else
      cell_text(pdf, chunk.map(&:to_s).join)
    end
  end
end

def cell_value(pdf, values)
  if values.size > 1
    table_content = values.map { |e| [e] }
    Prawn::Table.new(table_content, pdf, cell_style: { border_width: 0, padding: 1, align: :center })
  else
    values.first
  end
end

def print_table(pdf, data)
  table = data.children.filter('tr').map do |line|
    line.children.filter('th,td').map do |cells|
      values = cell_values(pdf, cells)
      cell_value(pdf, values)
    end
  end
  pdf.table table, position: :center, row_colors: ["F0EFEF", "FFFFFF"]
end

def print(pdf, text, size:)
  fragment = Nokogiri::HTML.fragment(text).children.reduce('') do |fragment, c|
    case (c.name)
    when 'img'
      print_text pdf, fragment, size
      print_image(pdf, c)
      ''
    when 'table'
      print_text pdf, fragment, size
      print_table(pdf, c)
      ''
    else
      fragment + c.to_s
    end
  end
  print_text pdf, fragment, size
end

def download_file_and_retry(file_or_attached_one, max_attempts = 3)
  if file_or_attached_one.is_a?(ActiveStorage::Attached::One)
    file_or_attached_one.download
  else
    file_or_attached_one.rewind && file_or_attached_one.read
  end
rescue Fog::OpenStack::Storage::NotFound => e
  if max_attempts > 0
    max_attempts = max_attempts - 1
    sleep 1
    retry
  else
    raise e
  end
end

prawn_document(margin: [top_margin, right_margin, bottom_margin, left_margin], page_size: page_size, info: info) do |pdf|
  pdf.font_families.update('marianne' => {
    normal: Rails.root.join('lib/prawn/fonts/marianne/marianne-regular.ttf'),
    bold: Rails.root.join('lib/prawn/fonts/marianne/marianne-bold.ttf'),
    bold_italic: Rails.root.join('lib/prawn/fonts/marianne/marianne-bold.ttf'),
    italic: Rails.root.join('lib/prawn/fonts/marianne/marianne-bold.ttf')
  })

  pdf.font 'marianne'

  grey = '555555'
  black = '000000'

  body_height = pdf.cursor - footer_height

  pdf.bounding_box([0, pdf.cursor], width: body_width, height: body_height) do
    logo_top_position = pdf.cursor
    if logo.present?
      logo_content = if logo.is_a?(ActiveStorage::Attached::One)
        logo.download
      else
        logo.rewind && logo.read
      end
      pdf.image StringIO.new(logo_content), fit: [max_logo_width, max_logo_height], position: :left
    end
    if qrcode.present? && md_version == :v2
      logo_bottom_position = pdf.cursor
      pdf.move_cursor_to logo_top_position
      qrcode_align = :right
      pdf.print_qr_code(qrcode, level: :q, extent: qrcode_size, margin: 5, align: qrcode_align)
      pdf.move_down 3
      pdf.text "<u><link href='#{qrcode}'>Scannez pour vérifier</link></u>", :inline_format => true, size: 9, align: qrcode_align, color: "0000FF"
      pdf.move_cursor_to [logo_bottom_position, pdf.cursor].min
    end
    pdf.fill_color grey
    pdf.pad_top(10) { pdf.text "le #{l(created_at, format: '%e %B %Y')}", size: 11, align: :right, character_spacing: -0.5 }

    pdf.fill_color black
    pdf.pad_top(30) { pdf.text title, character_spacing: -0.2, align: :center, inline_format: true, size: 18 }

    pdf.fill_color grey
    pdf.pad_top(30) do
      print pdf, body, size: 11
    end
    if signature.present?
      pdf.pad_top(20) do
        signature_content = if signature.is_a?(ActiveStorage::Attached::One)
          signature.download
        else
          signature.rewind && signature.read
        end
        pdf.image StringIO.new(signature_content), fit: [max_signature_size, max_signature_size], position: :right
      end
    end
  end

  pdf.repeat(:all) do
    margin = 2
    pdf.fill_color grey
    if qrcode.present? && md_version == :v1
      pdf.move_cursor_to footer_height
      qrcode_align = :center
      pdf.print_qr_code(qrcode, level: :q, extent: qrcode_size, margin: margin, align: qrcode_align)
      pdf.move_down 3
      pdf.text "<u><link href='#{qrcode}'>Scannez pour vérifier</link></u>", :inline_format => true, size: 9, align: qrcode_align, color: "0000FF"
    end
    if footer.present?
      pdf.move_cursor_to 20
      # We reduce the size of large footer so they can be drawn in the corresponding area.
      # This is due to a font change, the replacing font is slightly bigger than the previous one
      footer_font_size = footer.length > 170 ? 7 : 8
      pdf.text footer, align: :center, size: footer_font_size
    end
  end
end
