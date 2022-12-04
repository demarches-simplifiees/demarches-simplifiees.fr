class DossierRefuse < ApplicationEvent
  attribute :demarche_id, Decoder::UUID
  attribute :dossier_id, Decoder::UUID
  attribute :motivation, Decoder::Strict::String
end
