# frozen_string_literal: true

module Types
  class GroupeInstructeurType < Types::BaseObject
    description "Un groupe instructeur"

    global_id_field :id
    field :number, Int, "Le numero du groupe instructeur.", null: false, method: :id
    field :label, String, "Libellé du groupe instructeur.", null: false
    field :instructeurs, [Types::ProfileType], null: false
    field :closed, Boolean, "L’état du groupe instructeur.", null: false

    def instructeurs
      dataloader.with(Sources::Association, :instructeurs).load(object)
    end

    def self.authorized?(object, context)
      context.authorized_demarche?(object.procedure)
    end
  end
end
