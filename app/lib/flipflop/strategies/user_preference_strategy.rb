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
        legacy_enabled?(feature) || find_current_administrateur&.feature_enabled?(feature)
      end
    end

    private

    def legacy_enabled?(feature)
      if self.class.legacy_features_map.present?
        ids = self.class.legacy_features_map["#{feature}_allowed_for_admin_ids"]
        ids.present? && find_current_administrateur&.id&.in?(ids)
      end
    end

    LEGACY_CONFIG_FILE = Rails.root.join("config", "initializers", "features.yml")

    def self.legacy_features_map
      @@legacy_features_map = begin
        if File.exist?(LEGACY_CONFIG_FILE)
          YAML.load_file(LEGACY_CONFIG_FILE)
        end
      end
    end

    def find_current_administrateur
      if request.session["warden.user.user.key"]
        administrateur_id = request.session["warden.user.user.key"][0][0]
        Administrateur.find_by(id: administrateur_id)
      end
    end
  end
end
