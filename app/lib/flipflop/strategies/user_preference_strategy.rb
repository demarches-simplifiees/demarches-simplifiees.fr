module Flipflop::Strategies
  class UserPreferenceStrategy < AbstractStrategy
    def self.default_description
      "Allows configuration of features per user."
    end

    def switchable?
      false
    end

    def enabled?(feature)
      find_current_administrateur&.feature_enabled?(feature) ||
      find_current_gestionnaire&.feature_enabled?(feature)
    end

    private

    def find_current_administrateur
      administrateur_id = Current.administrateur&.id
      if administrateur_id
        Administrateur.find_by(id: administrateur_id)
      end
    end

    def find_current_gestionnaire
      gestionnaire_id = Current.gestionnaire&.id
      if gestionnaire_id
        Gestionnaire.find_by(id: gestionnaire_id)
      end
    end
  end
end
