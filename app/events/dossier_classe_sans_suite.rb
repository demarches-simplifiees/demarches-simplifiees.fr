class DossierClasseSansSuite < ApplicationEvent
  attribute :demarche_id, Decoder::UUID
  attribute :dossier_id, Decoder::UUID
  attribute :motivation, Decoder::Strict::String

  def self.encryption_schema
    { motivation: -> (data) { data.fetch(:dossier_id) } }
  end
end
