class Attestation < ApplicationRecord
  belongs_to :dossier

  mount_uploader :pdf, AttestationUploader
end
