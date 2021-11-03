class Champs::PieceJustificativeController < ApplicationController
  before_action :authenticate_logged_user!

  def update
    @champ = policy_scope(Champ).find(params[:champ_id])

    @champ.piece_justificative_file.attach(params[:blob_signed_id])
    if @champ.save
      render :show
    else
      errors = @champ.errors.full_messages
      render :json => { errors: errors }, :status => 422
    end
  end

  def download
    @champ = read_scope.find(params[:champ_id])
    if @champ&.is_a? Champs::PieceJustificativeChamp
      blob = @champ.piece_justificative_file
      if blob.filename.extension == 'pdf' && @champ.dossier.procedure.feature_enabled?(:qrcoded_pdf)
        send_data qrcoded(@champ), filename: blob.filename.to_s, type: 'application/pdf'
      else
        redirect_to blob.service_url, status: :found
      end
    else
      render :json => { errors: "Il n'y a pas de piece justificative #{params[:champ_id]}" }, :status => 404
    end
  end

  private

  include HexaPDF::Layout

  def qrcoded(champ)
    champ.piece_justificative_file.open do |file|
      doc = HexaPDF::Document.open(file)
      page = doc.pages[0]
      canvas = page.canvas(type: :overlay)
      url = Rails.application.routes.url_helpers.champs_piece_justificative_download_url({ champ_id: champ.id })
      page_height = page.box.height
      page_width = page.box.width
      wh = [page_width, page_height].max
      qrcode_size = wh * 4 / 100
      margin = wh * 1 / 150
      add_qrcode(canvas, margin, page_height - margin, qrcode_size, url)
      add_text(doc, canvas, margin + qrcode_size, margin, url)

      io = StringIO.new(''.b)
      doc.write(io)
      io.string
    end
  end

  HEADER = "Scannez le QRCode pour toujours télécharger la version officielle sur "

  def add_text(doc, canvas, left, margin, url)
    page = doc.pages[0]
    w = page.box.width / 2 - left
    h = 400
    wh = [page.box.width, page.box.height].max
    font = doc.fonts.add('Times')
    base_style = { font: font, font_size: [wh / 150, 8].max }
    layouter = TextLayouter.new(base_style)
    text = TextFragment.create(HEADER, **base_style)
    link = TextFragment.create('mes-demarches.gov.pf', **base_style, underline: true, fill_color: [0, 0, 255], overlays: [[:link, uri: url, border: true]])
    paragraph = layouter.fit([text, link], w - margin * 2, h)
    canvas.fill_color(255, 255, 255).rectangle(left, page.box.height - margin, w, -paragraph.height - margin * 2).fill
    paragraph.draw(canvas, left + margin, page.box.height - margin * 2)
  end

  def add_qrcode(canvas, x, y, qrcode_size, url)
    qrcode = RQRCode::QRCode.new(url)
    png = qrcode.as_png(
      bit_depth: 1,
      border_modules: 2,
      color_mode: ChunkyPNG::COLOR_GRAYSCALE,
      color: "red",
      fill: "white",
      module_px_size: 6,
      size: 120
    )
    qrcodeio = StringIO.new(png.to_s)
    canvas.image(qrcodeio, at: [x, y - qrcode_size], height: qrcode_size)
  end

  def read_scope
    policy_scope(Champ, policy_scope_class: ChampPolicy::ReadScope)
  end
end
