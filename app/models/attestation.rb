class Attestation < ApplicationRecord
  belongs_to :dossier

  mount_uploader :pdf, AttestationUploader

  def pdf_url
    if Rails.application.secrets.fog[:enabled]
      RemoteDownloader.new(pdf.path).url
    elsif pdf&.url
      # FIXME: this is horrible but used only in dev and will be removed after migration
      File.join(LOCAL_DOWNLOAD_URL, pdf.url)
    end
  end
end
