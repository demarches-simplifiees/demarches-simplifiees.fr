class Etablissement < ActiveRecord::Base
  belongs_to :dossier
  belongs_to :entreprise

  has_many :exercices

  def geo_adresse
    numero_voie.to_s << ' ' << type_voie.to_s << ' ' << nom_voie.to_s << ' ' << complement_adresse.to_s << ' ' << code_postal.to_s << ' ' << localite.to_s
  end
end
