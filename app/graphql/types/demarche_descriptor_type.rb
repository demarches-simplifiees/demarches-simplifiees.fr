module Types
  class DemarcheDescriptorType < Types::BaseObject
    description "Une demarche"

    global_id_field :id
    field :number, Int, "Le numero de la démarche.", null: false, method: :id
    field :title, String, "Le titre de la démarche.", null: false, method: :libelle
    field :description, String, "Description de la démarche.", null: false
    field :state, Types::DemarcheType::DemarcheState, "L'état de la démarche.", null: false

    def state
      object.aasm.current_state
    end
  end
end
