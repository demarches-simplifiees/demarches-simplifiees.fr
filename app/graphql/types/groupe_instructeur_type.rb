module Types
  class GroupeInstructeurType < Types::BaseObject
    description "Un groupe instructeur"

    global_id_field :id
    field :label, String, null: false
    field :instructeurs, [Types::ProfileType], null: false

    def instructeurs
      Loaders::Association.for(object.class, :instructeurs).load(object)
    end

    def self.authorized?(object, context)
      authorized_demarche?(object.procedure, context)
    end
  end
end
