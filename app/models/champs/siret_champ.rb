class Champs::SiretChamp < Champ
  belongs_to :etablissement, dependent: :destroy
  accepts_nested_attributes_for :etablissement, allow_destroy: true, update_only: true
end
