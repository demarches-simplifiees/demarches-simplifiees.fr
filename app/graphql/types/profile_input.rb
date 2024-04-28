# frozen_string_literal: true

module Types
  class ProfileInput < Types::BaseInputObject
    one_of
    argument :email, String, "Email", required: false
    argument :id, ID, "ID", required: false
  end
end
