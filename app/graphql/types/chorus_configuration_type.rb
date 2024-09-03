# frozen_string_literal: true

module Types
  class ChorusConfigurationType < Types::BaseObject
    field :centre_de_cout, String, "Le code du centre de cout auquel est rattaché la démarche.", null: true
    field :domaine_fonctionnel, String, "Le code du domaine fonctionnel auquel est rattaché la démarche.", null: true
    field :referentiel_de_programmation, String, "Le code du référentiel de programmation auquel est rattaché la démarche..", null: true

    def centre_de_cout
      object.centre_de_cout&.fetch("code") { '' }
    end

    def domaine_fonctionnel
      object.domaine_fonctionnel&.fetch("code") { '' }
    end

    def referentiel_de_programmation
      object.referentiel_de_programmation&.fetch("code") { '' }
    end
  end
end
