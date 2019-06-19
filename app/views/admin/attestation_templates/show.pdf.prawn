require 'prawn/measurement_extensions'
require 'prawn/qrcode'

info = {
        :Title => @title,
        :Subject => "Attestation pour un dossier",
        :Creator => "#{SITE_NAME}",
        :Producer => "Prawn",
        :CreationDate => @created_at
      }


#----- set page to A4 instead of letter
page_size = 'A4' # ou 'LETTER'
case page_size
when 'A4'
    page_height = 842
    page_width = 595
when 'LETTER'
    page_height = 1008
    page_width = 612
end

#----- margins
body_width = 400
top_margin = 50
bottom_margin = 20

right_margin = (page_width - body_width)/2
left_margin = right_margin

#----- size of images
max_logo_width = body_width
max_logo_height = 50.mm
max_signature_size = 50.mm
qrcode_size = 35.mm
footer_height = @qrcode.present? ? qrcode_size + 40 : 30

prawn_document(margin: [top_margin, right_margin, bottom_margin, left_margin], page_size: page_size, info: info) do |pdf|
  pdf.font_families.update( 'liberation serif' => { normal: Rails.root.join('lib/prawn/fonts/liberation_serif/LiberationSerif-Regular.ttf' )})
  pdf.font 'liberation serif'

  grey = '555555'
  red = 'C52F24'
  black = '000000'

  body_height = pdf.cursor - footer_height

  pdf.bounding_box([0, pdf.cursor], width: body_width, height: body_height) do
    if @logo.present?
      pdf.image StringIO.new(@logo.read), fit: [max_logo_width , max_logo_height], position: :center
    end

    pdf.fill_color grey
    pdf.pad_top(40) { pdf.text "le #{l(@created_at, format: '%e %B %Y')}", size: 10, align: :right, character_spacing: -0.5 }

    pdf.fill_color black
    pdf.pad_top(40) { pdf.text @title, size: 20, inline_format: true }

    pdf.fill_color grey
    pdf.pad_top(30) { pdf.text @body, size: 12, character_spacing: -0.2, align: :justify, inline_format: true }

    cpos = pdf.cursor - 40
    if @signature.present?
      pdf.pad_top(40) do
        pdf.image StringIO.new(@signature.read), fit: [max_signature_size , max_signature_size], position: :right
      end
    end

  end

  pdf.repeat(:all) do
    margin = 2
    pdf.fill_color grey
    if @qrcode.present?
      pdf.move_cursor_to footer_height
      pdf.print_qr_code(@qrcode, level: :q, extent: qrcode_size, margin: margin, align: :center)
      pdf.move_down 3
      pdf.text "<u><link href='#{@qrcode}'>#{@title}</link></u>",:inline_format => true, size: 9, align: :center, color: "0000FF"
    end
    pdf.move_cursor_to 20
    pdf.text @footer, align: :center, size: 8
  end
end
