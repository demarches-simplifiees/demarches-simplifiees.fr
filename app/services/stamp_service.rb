# frozen_string_literal: true

class StampService
  def stamp(blob, url)
    blob.open do |file|
      doc = HexaPDF::Document.open(file)
      page = doc.pages[0]
      canvas = page.canvas(type: :overlay)
      page_height = page.box.height
      page_width = page.box.width
      wh = [page_width, page_height].max
      qrcode_size = wh * 5 / 100
      margin = wh * 1 / 70

      add_qrcode(canvas, margin, page_height - margin, qrcode_size, url)
      add_text(doc, canvas, margin + qrcode_size, margin, url)

      pdf_string(doc)
    end
  end

  private

  include HexaPDF::Layout

  def pdf_string(doc)
    io = StringIO.new(''.b)
    doc.write(io)
    io.string
  end

  HEADER = "Scannez le code QR pour télécharger la version officielle sur "

  def add_text(doc, canvas, left, margin, url)
    page = doc.pages[0]
    w = page.box.width * 70 / 100 - left
    h = 400
    wh = [page.box.width, page.box.height].max
    font = doc.fonts.add('Times', variant: :bold)
    font_size = [wh / 110, 8].max
    base_style = { font: font, font_size: font_size }
    layouter = TextLayouter.new(base_style)
    text = TextFragment.create(HEADER, **base_style)
    link = TextFragment.create('mes-demarches.gov.pf', **base_style, underline: true, fill_color: [0, 0, 255], overlays: [[:link, uri: url, border: true]])
    paragraph = layouter.fit([text, link], w - margin, h)
    canvas.fill_color(255, 255, 255).rectangle(left, page.box.height - margin, w, -paragraph.height - margin).fill
    paragraph.draw(canvas, left, page.box.height - margin * 3 / 2)
  end

  def add_qrcode(canvas, x, y, qrcode_size, url)
    qrcode = RQRCode::QRCode.new(url)
    png = qrcode.as_png(
      bit_depth: 1,
      border_modules: 2,
      color_mode: ChunkyPNG::COLOR_GRAYSCALE,
      color: '#ab0000',
      fill: "white",
      module_px_size: 6,
      size: 120
    )
    qrcodeio = StringIO.new(png.to_s)
    canvas.image(qrcodeio, at: [x, y - qrcode_size], height: qrcode_size)
  end
end
