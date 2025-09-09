# frozen_string_literal: true

require 'prawn/measurement_extensions'

prawn_document(margin: [50, 100, 20, 50], page_size: 'A4') do |pdf|
  grey = '555555'
  black = '333333'
  max_logo_width = 4.cm
  max_logo_height = 3.cm
  max_signature_size = 2.cm

  if @attestation.fetch(:logo).present?
    logo_content = @attestation.fetch(:logo).download
    pdf.image StringIO.new(logo_content), fit: [max_logo_width, max_logo_height], position: :left
  end

  pdf.fill_color grey
  pdf.pad_top(40) do
    pdf.text "le #{l(@attestation.fetch(:created_at), format: '%d %B %Y')}", size: 10, align: :right, character_spacing: -0.5
  end

  pdf.fill_color black
  pdf.pad_top(40) do
    pdf.text @attestation.fetch(:title), size: 18, character_spacing: -0.2 if @attestation.fetch(:title).present?
  end

  pdf.pad_top(30) do
    pdf.text @attestation.fetch(:body), size: 10, character_spacing: -0.2, align: :justify if @attestation.fetch(:body).present?
  end

  if @attestation.fetch(:signature).present?
    pdf.pad_top(40) do
      signature_content = @attestation.fetch(:signature).download
      pdf.image StringIO.new(signature_content), fit: [max_signature_size, max_signature_size], position: :right
    end
  end

  pdf.repeat :all do
    # Footer
    if @attestation.fetch(:footer).present?
      pdf.fill_color grey
      pdf.number_pages '<page> / <total>', {
        at: [0, -15],
        align: :right,
        size: 9
      }
      pdf.fill_color grey
      pdf.draw_text @attestation.fetch(:footer), at: [0, -15], size: 8
    else
      pdf.fill_color grey
      pdf.number_pages '<page> / <total>', {
        at: [0, -15],
        align: :center,
        size: 9
      }
    end
  end
end