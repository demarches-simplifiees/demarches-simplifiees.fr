class DossierProcedureSerializer < ActiveModel::Serializer
  attributes :id,
             :created_at,
             :updated_at,
             :archived,
             :mandataire_social,
             :state

  attribute :followers_gestionnaires_emails, key: :emails_accompagnateurs
end
