# frozen_string_literal: true

class CloneReferentielService
  def self.clone_referentiel(original, kopy, same_admin)
    case [kopy.referentiel, same_admin]
    in [Referentiels::APIReferentiel, true] # cloned from same admin, dup referentiel and keep api key
      kopy.referentiel = original.referentiel.dup
    in [Referentiels::APIReferentiel, false] # cloned from another admin, dup referentiel but discard api key/last_response
      kopy.referentiel = original.referentiel.dup.tap do
        it.authentication_data = nil
        it.last_response = nil
      end
    in [Referentiels::CsvReferentiel, _] # for CSV referentiel, just use the same referentiel_id
      kopy.referentiel_id = original.referentiel_id
    else
      # no op
    end
  end
end
