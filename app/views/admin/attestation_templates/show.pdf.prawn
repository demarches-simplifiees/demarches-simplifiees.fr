require 'prawn/measurement_extensions'

prawn_document(margin: [50, 100, 20, 100]) do |pdf|
  pdf.font_families.update( 'liberation serif' => { normal: Rails.root.join('lib/prawn/fonts/liberation_serif/LiberationSerif-Regular.ttf' )})
  pdf.font 'liberation serif'

  grey = '555555'
  black = '333333'
  max_logo_size = 40.mm
  max_signature_size = 40.mm

  pdf.bounding_box([0, pdf.cursor], width: 400, height: 650) do
    if @logo.present?
      pdf.image StringIO.new(@logo.read), fit: [max_logo_size , max_logo_size], position: :center
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
    pdf.move_cursor_to 20
    pdf.fill_color grey
    pdf.text @footer, align: :center, size: 8
  end
end
