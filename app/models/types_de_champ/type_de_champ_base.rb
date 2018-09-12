class TypesDeChamp::TypeDeChampBase
  include ActiveModel::Validations

  def initialize(type_de_champ)
    @type_de_champ = type_de_champ
  end
end
