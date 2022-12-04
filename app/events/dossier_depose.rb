class DossierDepose < ApplicationEvent
  attribute :demarche_id, Decoder::UUID
  attribute :dossier_id, Decoder::UUID
end
