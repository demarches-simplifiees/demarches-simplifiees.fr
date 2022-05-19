module Types
  class RevisionType < Types::BaseObject
    global_id_field :id
    field :date_creation, GraphQL::Types::ISO8601DateTime, "Date de la création.", null: false, method: :created_at
    field :date_publication, GraphQL::Types::ISO8601DateTime, "Date de la publication.", null: true, method: :published_at

    field :champ_descriptors, [Types::ChampDescriptorType], null: false
    field :annotation_descriptors, [Types::ChampDescriptorType], null: false

    def champ_descriptors
      Loaders::Association.for(object.class, :types_de_champ_public).load(object)
    end

    def annotation_descriptors
      Loaders::Association.for(object.class, :types_de_champ_private).load(object)
    end
  end
end
