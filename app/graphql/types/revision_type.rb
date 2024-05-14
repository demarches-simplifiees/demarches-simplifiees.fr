# frozen_string_literal: true

module Types
  class RevisionType < Types::BaseObject
    global_id_field :id
    field :date_creation, GraphQL::Types::ISO8601DateTime, "Date de la création.", null: false, method: :created_at
    field :date_publication, GraphQL::Types::ISO8601DateTime, "Date de la publication.", null: true, method: :published_at

    field :champ_descriptors, [Types::ChampDescriptorType], null: false
    field :annotation_descriptors, [Types::ChampDescriptorType], null: false

    def champ_descriptors
      Loaders::Association.for(object.class, revision_types_de_champ_public: :type_de_champ).load(object)
    end

    def annotation_descriptors
      if context.authorized_demarche?(object.procedure, opendata: true)
        Loaders::Association.for(object.class, revision_types_de_champ_private: :type_de_champ).load(object)
      else
        []
      end
    end
  end
end
