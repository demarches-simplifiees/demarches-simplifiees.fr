# frozen_string_literal: true

module Types
  class BaseObject < GraphQL::Schema::Object
    field_class BaseField
  end
end
