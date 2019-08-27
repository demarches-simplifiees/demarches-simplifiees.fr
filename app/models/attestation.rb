class Attestation < ApplicationRecord
  belongs_to :dossier

  mount_uploader :pdf, AttestationUploader

  has_one_attached :pdf_active_storage

  def pdf_url
    if pdf_active_storage.attached?
      Rails.application.routes.url_helpers.url_for(pdf_active_storage)
    elsif Rails.application.secrets.fog[:enabled]
      RemoteDownloader.new(pdf.path).url
    elsif pdf&.url
      # FIXME: this is horrible but used only in dev and will be removed after migration
      File.join(LOCAL_DOWNLOAD_URL, pdf.url)
    end
  end
end
