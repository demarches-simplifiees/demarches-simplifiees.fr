module Types
  class BaseObject < GraphQL::Schema::Object
    def self.authorized_demarche?(object, context)
      if context[:administrateur_id]
        object.administrateur_id == context[:administrateur_id]
      elsif context[:token]
        if object.administrateur.valid_api_token?(context[:token])
          context[:administrateur_id] = object.administrateur_id
          true
        end
      end
    end
  end
end
