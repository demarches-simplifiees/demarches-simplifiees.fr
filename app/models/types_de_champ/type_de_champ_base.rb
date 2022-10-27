class TypesDeChamp::TypeDeChampBase
  include ActiveModel::Validations

  delegate :description, :libelle, :mandatory, :stable_id, to: :@type_de_champ

  FILL_DURATION_SHORT  = 10.seconds.in_seconds
  FILL_DURATION_MEDIUM = 1.minute.in_seconds
  FILL_DURATION_LONG   = 3.minutes.in_seconds

  def initialize(type_de_champ)
    @type_de_champ = type_de_champ
  end

  def tags_for_template
    stable_id = self.stable_id
    [
      {
        libelle: libelle.gsub(/[[:space:]]/, ' '),
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

  # Default estimated duration to fill the champ in a form, in seconds.
  # May be overridden by subclasses.
  def estimated_fill_duration(revision)
    FILL_DURATION_SHORT
  end

  def build_champ(params)
    @type_de_champ.champ.build(params)
  end

  def filter_to_human(filter_value)
    filter_value
  end

  def human_to_filter(human_value)
    human_value
  end
end
