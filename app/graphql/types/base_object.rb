module Types
  class BaseObject < GraphQL::Schema::Object
    def self.authorized_demarche?(demarche, context)
      # We are caching authorization logic because it is called for each node
      # of the requested graph and can be expensive. Context is reset per request so it is safe.
      context[:authorized] ||= {}
      if context[:authorized][demarche.id]
        return true
      end

      administrateur = demarche.administrateurs.find do |administrateur|
        if context[:token]
          administrateur.valid_api_token?(context[:token])
        else
          administrateur.id == context[:administrateur_id]
        end
      end

      if administrateur
        context[:authorized][demarche.id] = true
        true
      end
    end
  end
end
