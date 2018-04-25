module Flipflop::Strategies
  class UserPreferenceStrategy < AbstractStrategy
    def self.default_description
      "Allows configuration of features per user."
    end

    def switchable?
      false
    end

    def enabled?(feature)
      # Can only check features if we have the user's session.
      if request?
        find_current_administrateur&.feature_enabled?(feature)
      end
    end

    private

    def find_current_administrateur
      if request.session["warden.user.administrateur.key"]
        administrateur_id = request.session["warden.user.administrateur.key"][0][0]
        Administrateur.find_by(id: administrateur_id)
      end
    end
  end
end
