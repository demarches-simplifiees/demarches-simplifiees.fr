class Champs::NumberChamp < Champ
  validates :value, numericality: { message: Proc.new { |champ, _| "#{champ.libelle} doit être un nombre" } }
  validates :value,
    numericality: { only_integer: true, message: Proc.new { |champ, _| "#{champ.libelle} doit être un nombre entier" } },
    if: Proc.new{ |object| object.errors.empty? }
end
