class TypesDeChamp::TypeDeChampBase
  include ActiveModel::Validations

  delegate :description, :libelle, to: :@type_de_champ

  def initialize(type_de_champ)
    @type_de_champ = type_de_champ
  end

  def tags_for_template
    l = libelle
    [
      {
        libelle: l,
        description: description,
        lambda: -> (champs) {
          champs.detect { |champ| champ.libelle == l }
        }
      }
    ]
  end

  def build_champ
    @type_de_champ.champ.build
  end
end
