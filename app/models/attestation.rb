class Attestation < ApplicationRecord
  belongs_to :dossier, -> { unscope(where: :hidden_at) }

  mount_uploader :pdf, AttestationUploader
end
