class TypesDeChamp::TypeDeChampBase
  include ActiveModel::Validations

  delegate :description, :libelle, :stable_id, to: :@type_de_champ

  def initialize(type_de_champ)
    @type_de_champ = type_de_champ
  end

  def tags_for_template
    stable_id = self.stable_id
    [
      {
        libelle: libelle,
        id: "tdc#{stable_id}",
        description: description,
        lambda: -> (champs) {
          champs.find { |champ| champ.stable_id == stable_id }&.for_tag
        }
      }
    ]
  end

  def libelle_for_export(index = 0)
    libelle
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

  def condition_operators
    []
  end

  def condition_values
    []
  end

  def default_condition_operator
    condition_operators.first&.last
  end

  def default_condition_value
    condition_values.first&.last
  end
end
