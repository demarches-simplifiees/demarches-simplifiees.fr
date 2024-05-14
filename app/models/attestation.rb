# frozen_string_literal: true

class Attestation < ApplicationRecord
  belongs_to :dossier, optional: false

  has_one_attached :pdf

  def pdf_url
    if pdf.attached?
      Rails.application.routes.url_helpers.url_for(pdf)
    end
  end
end
