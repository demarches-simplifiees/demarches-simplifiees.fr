class TypesDeChamp::TypeDeChampBase
  include ActiveModel::Validations

  delegate :description, :libelle, to: :@type_de_champ

  def initialize(type_de_champ)
    @type_de_champ = type_de_champ
  end

  def tags_for_template
    tdc = @type_de_champ
    [
      {
        libelle: libelle,
        description: description,
        lambda: -> (champs) {
          champs.find { |champ| champ.type_de_champ == tdc }&.for_tag
        }
      }
    ]
  end

  def build_champ
    @type_de_champ.champ.build
  end
end
