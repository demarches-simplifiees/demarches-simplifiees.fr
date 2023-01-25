class TypesDeChamp::TypeDeChampBase
  include ActiveModel::Validations

  delegate :description, :libelle, :mandatory, :stable_id, :fillable?, to: :@type_de_champ

  FILL_DURATION_SHORT  = 10.seconds
  FILL_DURATION_MEDIUM = 1.minute
  FILL_DURATION_LONG   = 3.minutes
  READ_WORDS_PER_SECOND = 140.0 / 60 # 140 words per minute

  def initialize(type_de_champ)
    @type_de_champ = type_de_champ
  end

  def tags_for_template
    stable_id = self.stable_id
    [
      {
        libelle: TagsSubstitutionConcern::TagsParser.normalize(libelle),
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
    if fillable?
      FILL_DURATION_SHORT
    else
      0.seconds
    end
  end

  def estimated_read_duration
    return 0.seconds if description.blank?

    sanitizer = Rails::Html::Sanitizer.full_sanitizer.new
    content = sanitizer.sanitize(description)

    words = content.split(/\s+/).size

    (words / READ_WORDS_PER_SECOND).round.seconds
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

  def pattern
    "/^.{0,255}$/"
  end
end
