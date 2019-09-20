class Attestation < ApplicationRecord
  self.ignored_columns = ['pdf', 'content_secure_token']

  belongs_to :dossier

  has_one_attached :pdf

  def pdf_url
    if pdf.attached?
      Rails.application.routes.url_helpers.url_for(pdf)
    end
  end
end
