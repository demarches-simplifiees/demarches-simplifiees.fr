require 'prawn/measurement_extensions'

#----- A4 page size
page_size = 'A4'
page_height = 842
page_width = 595

#----- margins
body_width = 400
top_margin = 50
bottom_margin = 20
footer_height = top_margin - bottom_margin

right_margin = (page_width - body_width)/2
left_margin = right_margin

#----- size of images
max_logo_width = body_width
max_logo_height = 50.mm
max_signature_size = 50.mm

prawn_document(margin: [top_margin, right_margin, bottom_margin, left_margin], page_size: page_size) do |pdf|
  pdf.font_families.update( 'liberation serif' => { normal: Rails.root.join('lib/prawn/fonts/liberation_serif/LiberationSerif-Regular.ttf' )})
  pdf.font 'liberation serif'

  grey = '555555'
  black = '333333'

  body_height = pdf.cursor - footer_height

  pdf.bounding_box([0, pdf.cursor], width: body_width, height: body_height) do
    if @logo.present?
      pdf.image StringIO.new(@logo.read), fit: [max_logo_width , max_logo_height], position: :center
    end

    pdf.fill_color grey
    pdf.pad_top(40) { pdf.text "le #{l(@created_at, format: '%e %B %Y')}", size: 10, align: :right, character_spacing: -0.5 }

    pdf.fill_color black
    pdf.pad_top(40) { pdf.text @title, size: 18, character_spacing: -0.2 }

    pdf.fill_color grey
    pdf.pad_top(30) { pdf.text @body, size: 10, character_spacing: -0.2, align: :justify }

    if @signature.present?
      pdf.pad_top(40) do
        pdf.image StringIO.new(@signature.read), fit: [max_signature_size , max_signature_size], position: :right
      end
    end
  end

  pdf.repeat(:all) do
    pdf.move_cursor_to footer_height - 10
    pdf.fill_color grey
    pdf.text @footer, align: :center, size: 8
  end
end
