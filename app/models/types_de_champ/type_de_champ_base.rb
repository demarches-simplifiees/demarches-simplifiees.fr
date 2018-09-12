class TypesDeChamp::TypeDeChampBase
  include ActiveModel::Validations

  delegate :libelle, to: :@type_de_champ

  def initialize(type_de_champ)
    @type_de_champ = type_de_champ
  end
end
