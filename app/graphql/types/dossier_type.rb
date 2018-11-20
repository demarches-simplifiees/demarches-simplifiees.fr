module Types
  class DossierType < Types::BaseObject
    description "Un dossier"

    field :id, ID, "L'ID du dossier.", null: false
    field :state, Types::DossierStateType, "L'état du dossier.", null: false
    field :created_at, GraphQL::Types::ISO8601DateTime, null: false
    field :updated_at, GraphQL::Types::ISO8601DateTime, null: false
    field :motivation, String, null: true

    field :usager, Types::ProfileType, null: false
    field :instructeurs, [Types::ProfileType], null: false

    def state
      object.state
    end

    def usager
      Loaders::Record.for(User).load(object.user_id)
    end

    def instructeurs
      Loaders::Association.for(Dossier, :followers_gestionnaires).load(object)
    end
  end
end
