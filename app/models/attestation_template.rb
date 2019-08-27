class AttestationTemplate < ApplicationRecord
  include ActionView::Helpers::NumberHelper
  include TagsSubstitutionConcern

  belongs_to :procedure

  mount_uploader :logo, AttestationTemplateLogoUploader
  mount_uploader :signature, AttestationTemplateSignatureUploader

  has_one_attached :logo_active_storage
  has_one_attached :signature_active_storage

  validates :footer, length: { maximum: 190 }

  DOSSIER_STATE = Dossier.states.fetch(:accepte)

  def attestation_for(dossier)
    attestation = Attestation.new(title: replace_tags(title, dossier))
    attestation.pdf_active_storage.attach(
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

    if logo_active_storage.attached?
      attestation_template.logo_active_storage.attach(
        io: StringIO.new(logo_active_storage.download),
        filename: logo_active_storage.filename,
        content_type: logo_active_storage.content_type,
        # we don't want to run virus scanner on duplicated file
        metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
      )
    elsif logo.present?
      CopyCarrierwaveFile::CopyFileService.new(self, attestation_template, :logo).set_file
    end

    if signature_active_storage.attached?
      attestation_template.signature_active_storage.attach(
        io: StringIO.new(signature_active_storage.download),
        filename: signature_active_storage.filename,
        content_type: signature_active_storage.content_type,
        # we don't want to run virus scanner on duplicated file
        metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
      )
    elsif signature.present?
      CopyCarrierwaveFile::CopyFileService.new(self, attestation_template, :signature).set_file
    end

    attestation_template
  end

  def logo?
    logo_active_storage.attached? || logo.present?
  end

  def signature?
    signature_active_storage.attached? || signature.present?
  end

  def logo_url
    if logo_active_storage.attached?
      Rails.application.routes.url_helpers.url_for(logo_active_storage)
    elsif logo.present?
      if Rails.application.secrets.fog[:enabled]
        RemoteDownloader.new(logo.path).url
      elsif logo&.url
        # FIXME: this is horrible but used only in dev and will be removed after migration
        File.join(LOCAL_DOWNLOAD_URL, logo.url)
      end
    end
  end

  def signature_url
    if signature_active_storage.attached?
      Rails.application.routes.url_helpers.url_for(signature_active_storage)
    elsif signature.present?
      if Rails.application.secrets.fog[:enabled]
        RemoteDownloader.new(signature.path).url
      elsif signature&.url
        # FIXME: this is horrible but used only in dev and will be removed after migration
        File.join(LOCAL_DOWNLOAD_URL, signature.url)
      end
    end
  end

  def proxy_logo
    if logo_active_storage.attached?
      logo_active_storage
    else
      logo
    end
  end

  def proxy_signature
    if signature_active_storage.attached?
      signature_active_storage
    else
      signature
    end
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
      title: replace_tags(title, dossier),
      body: replace_tags(body, dossier),
      signature: proxy_signature,
      footer: footer,
      created_at: Time.zone.now)

    attestation_view = action_view.render(file: 'admin/attestation_templates/show', formats: [:pdf])

    StringIO.new(attestation_view)
  end
end
