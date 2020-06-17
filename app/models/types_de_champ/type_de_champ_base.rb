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

  def filter_to_human(filter_value)
    filter_value
  end

  def human_to_filter(human_value)
    human_value
  end
end
