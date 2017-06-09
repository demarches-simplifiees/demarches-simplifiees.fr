class Attestation < ApplicationRecord
  belongs_to :dossier

  mount_uploader :pdf, AttestationUploader

  MAX_SIZE_EMAILABLE = 2.megabytes

  def emailable?
    pdf.size <= MAX_SIZE_EMAILABLE
  end
end
