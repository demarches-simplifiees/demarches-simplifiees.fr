# == Schema Information
#
# Table name: attestations
#
#  id         :integer          not null, primary key
#  title      :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  dossier_id :integer          not null
#
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
