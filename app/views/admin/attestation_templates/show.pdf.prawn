require 'prawn/measurement_extensions'

prawn_document(margin: [50, 100, 20, 100], page_size: "A4",page_layout: :portrait) do |pdf|
  pdf.font_families.update( 'OpenSans' => {
    normal: './lib/prawn/fonts/OpenSans-Regular.ttf',
    italic: './lib/prawn/fonts/OpenSans-Italic.ttf',
    bold: './lib/prawn/fonts/OpenSans-Bold.ttf',
    bold_italic: './lib/prawn/fonts/OpenSans-BoldItalic.ttf'
  })

  pdf.font 'OpenSans'

  grey = '555555'
  black = '000000'
  max_logo_width = 200.mm
  max_logo_height = 50.mm
  max_signature_size = 50.mm

  pdf.bounding_box([0, pdf.cursor], width: 400, height: 650) do
    if @logo.present?
      pdf.image StringIO.new(@logo.read), fit: [max_logo_width , max_logo_height], position: :center
    end

    pdf.fill_color grey
    pdf.pad_top(40) { pdf.text "le #{l(@created_at, format: '%e %B %Y')}", size: 10, align: :right, character_spacing: -0.5 }

    pdf.fill_color black
    pdf.pad_top(40) { pdf.text @title, size: 20, inline_format: true }

    pdf.fill_color grey
    pdf.pad_top(30) { pdf.text @body, size: 12, inline_format: true }

    if @signature.present?
      pdf.pad_top(40) do
        pdf.image StringIO.new(@signature.read), fit: [max_signature_size , max_signature_size], position: :right
      end
    end
  end

  pdf.repeat(:all) do
    pdf.move_cursor_to 20
    pdf.fill_color grey
    pdf.text @footer, align: :center, size: 8
  end
end
