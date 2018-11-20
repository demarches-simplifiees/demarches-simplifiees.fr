module Types
  class ProfileType < Types::BaseObject
    global_id_field :id
    field :email, String, null: false
  end
end
