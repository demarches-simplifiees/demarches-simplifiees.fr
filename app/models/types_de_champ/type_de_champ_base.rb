class TypesDeChamp::TypeDeChampBase
  include ActiveModel::Validations

  delegate :description, :libelle, :mandatory, :mandatory?, :stable_id, :fillable?, :public?, to: :@type_de_champ

  FILL_DURATION_SHORT  = 10.seconds
  FILL_DURATION_MEDIUM = 1.minute
  FILL_DURATION_LONG   = 3.minutes
  READ_WORDS_PER_SECOND = 140.0 / 60 # 140 words per minute

  def initialize(type_de_champ)
    @type_de_champ = type_de_champ
  end

  def paths
    [
      {
        libelle:,
        path: :value,
        description:,
        maybe_null: public? && !mandatory?
      }
    ]
  end

  def tags_for_template
    paths.map {
      _1.merge(
        libelle: TagsSubstitutionConcern::TagsParser.normalize(_1[:libelle]),
        id: _1[:path] == :value ? "tdc#{stable_id}" : "tdc#{stable_id}/#{_1[:path]}",
        lambda: -> (dossier) {
          dossier.project_champ(@type_de_champ, nil).for_tag(_1[:path])
        }
      )
    }
  end

  def libelles_for_export
    paths.map { [_1[:libelle], _[:path]] }
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

  def filter_to_human(filter_value)
    filter_value
  end

  def human_to_filter(human_value)
    human_value
  end
end
