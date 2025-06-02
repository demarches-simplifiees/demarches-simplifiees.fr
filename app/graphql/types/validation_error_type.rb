# frozen_string_literal: true

module Types
  class ValidationErrorType < Types::BaseObject
    description "Éreur de validation"

    field :message, String, "A description of the error", null: false

    def message
      object
    end
  end
end
