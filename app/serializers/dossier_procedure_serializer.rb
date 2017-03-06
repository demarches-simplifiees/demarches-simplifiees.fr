class DossierProcedureSerializer < ActiveModel::Serializer
  attributes :id,
             :created_at,
             :updated_at,
             :archived,
             :mandataire_social,
             :state,
             :initiated_at,
             :received_at,
             :processed_at

  attribute :followers_gestionnaires_emails, key: :emails_accompagnateurs
end
