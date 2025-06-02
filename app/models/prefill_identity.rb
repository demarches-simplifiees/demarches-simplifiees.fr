# frozen_string_literal: true

class PrefillIdentity
  attr_reader :dossier, :params

  def initialize(dossier, params)
    @dossier = dossier
    @params = params
  end

  def to_h
    if dossier.procedure.for_individual?
      {
        prenom: params["identite_prenom"],
        nom: params["identite_nom"],
        gender: ["M.", "Mme"].include?(params["identite_genre"]) ? params["identite_genre"] : nil
      }
    else
      {}
    end
  end
end
