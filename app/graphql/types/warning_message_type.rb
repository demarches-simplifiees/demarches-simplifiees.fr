# frozen_string_literal: true

module Types
  class WarningMessageType < Types::BaseObject
    description "Message d’alerte"

    field :message, String, "La description de l’alerte", null: false

    def message
      object
    end
  end
end
