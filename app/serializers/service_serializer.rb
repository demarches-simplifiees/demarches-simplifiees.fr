class ServiceSerializer < ActiveModel::Serializer
  attributes :id, :siret, :email
  attribute :nom, key: :name
  attribute :type_organisme, key: :type_organization
  attribute :organisme, key: :organization
  attribute :telephone, key: :phone
  attribute :horaires, key: :schedule
  attribute :adresse, key: :address
end
