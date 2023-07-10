module Types
  class BaseObject < GraphQL::Schema::Object
    field_class BaseField
  end
end
