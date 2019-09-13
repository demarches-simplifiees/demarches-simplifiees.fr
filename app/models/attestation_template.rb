class AttestationTemplate < ApplicationRecord
  self.ignored_columns = ['logo', 'signature']

  include ActionView::Helpers::NumberHelper
  include TagsSubstitutionConcern

  belongs_to :procedure

  has_one_attached :logo
  has_one_attached :logo_active_storage
  has_one_attached :signature
  has_one_attached :signature_active_storage

  validates :footer, length: { maximum: 190 }

  DOSSIER_STATE = Dossier.states.fetch(:accepte)

  def attestation_for(dossier)
    attestation = Attestation.new(title: replace_tags(title, dossier))
    attestation.pdf.attach(
      io: build_pdf(dossier),
      filename: "attestation-dossier-#{dossier.id}.pdf",
      content_type: 'application/pdf',
      # we don't want to run virus scanner on this file
      metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
    )
    attestation
  end

  def unspecified_champs_for_dossier(dossier)
    all_champs_with_libelle_index = (dossier.champs + dossier.champs_private)
      .reduce({}) do |acc, champ|
      acc[champ.libelle] = champ
      acc
    end

    used_tags.map do |used_tag|
      corresponding_champ = all_champs_with_libelle_index[used_tag]

      if corresponding_champ && corresponding_champ.value.blank?
        corresponding_champ
      end
    end.compact
  end

  def dup
    attestation_template = AttestationTemplate.new(title: title, body: body, footer: footer, activated: activated)

    if logo.attached?
      attestation_template.logo.attach(
        io: StringIO.new(logo.download),
        filename: logo.filename.to_s,
        content_type: logo.content_type,
        # we don't want to run virus scanner on duplicated file
        metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
      )
    elsif logo_active_storage.attached?
      attestation_template.logo.attach(
        io: StringIO.new(logo_active_storage.download),
        filename: logo_active_storage.filename.to_s,
        content_type: logo_active_storage.content_type,
        # we don't want to run virus scanner on duplicated file
        metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
      )
    end

    if signature.attached?
      attestation_template.signature.attach(
        io: StringIO.new(signature.download),
        filename: signature.filename.to_s,
        content_type: signature.content_type,
        # we don't want to run virus scanner on duplicated file
        metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
      )
    elsif signature_active_storage.attached?
      attestation_template.signature.attach(
        io: StringIO.new(signature_active_storage.download),
        filename: signature_active_storage.filename.to_s,
        content_type: signature_active_storage.content_type,
        # we don't want to run virus scanner on duplicated file
        metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
      )
    end

    attestation_template
  end

  def logo?
    logo.attached? || logo_active_storage.attached?
  end

  def signature?
    signature.attached? || signature_active_storage.attached?
  end

  def logo_url
    if logo.attached?
      Rails.application.routes.url_helpers.url_for(logo)
    elsif logo_active_storage.attached?
      Rails.application.routes.url_helpers.url_for(logo_active_storage)
    end
  end

  def signature_url
    if signature.attached?
      Rails.application.routes.url_helpers.url_for(signature)
    elsif signature_active_storage.attached?
      Rails.application.routes.url_helpers.url_for(signature_active_storage)
    end
  end

  def proxy_logo
    if logo.attached?
      logo
    elsif logo_active_storage.attached?
      logo_active_storage
    end
  end

  def proxy_signature
    if signature.attached?
      signature
    elsif signature_active_storage.attached?
      signature_active_storage
    end
  end

  def title_for_dossier(dossier)
    replace_tags(title, dossier)
  end

  def body_for_dossier(dossier)
    replace_tags(body, dossier)
  end

  private

  def used_tags
    delimiters_regex = /--(?<capture>((?!--).)*)--/

    # We can't use flat_map as scan will return 3 levels of array,
    # using flat_map would give us 2, whereas flatten will
    # give us 1, which is what we want
    [title, body]
      .map { |str| str.scan(delimiters_regex) }
      .flatten
  end

  def build_pdf(dossier)
    action_view = ActionView::Base.new(ActionController::Base.view_paths,
      logo: proxy_logo,
      title: title_for_dossier(dossier),
      body: body_for_dossier(dossier),
      signature: proxy_signature,
      footer: footer,
      qrcode: qrcode_dossier_url(dossier, created_at: dossier.encoded_date(:created_at)),
      created_at: Time.zone.now)

    attestation_view = action_view.render(file: 'admin/attestation_templates/show', formats: [:pdf])

    StringIO.new(attestation_view)
  end
end
