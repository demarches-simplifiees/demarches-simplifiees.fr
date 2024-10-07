# frozen_string_literal: true

class TypesDeChamp::TypeDeChampBase
  include ActiveModel::Validations

  delegate :description, :libelle, :mandatory, :mandatory?, :stable_id, :fillable?, :public?, :type_champ, to: :@type_de_champ

  FILL_DURATION_SHORT  = 10.seconds
  FILL_DURATION_MEDIUM = 1.minute
  FILL_DURATION_LONG   = 3.minutes
  READ_WORDS_PER_SECOND = 140.0 / 60 # 140 words per minute

  def initialize(type_de_champ)
    @type_de_champ = type_de_champ
  end

  def tags_for_template
    tdc = @type_de_champ
    paths.map do |path|
      path.merge(
        libelle: TagsSubstitutionConcern::TagsParser.normalize(path[:libelle]),
        id: path[:path] == :value ? "tdc#{stable_id}" : "tdc#{stable_id}/#{path[:path]}",
        lambda: -> (dossier) { dossier.project_champ(tdc, nil).for_tag(path[:path]) }
      )
    end
  end

  def libelles_for_export
    paths.map { [_1[:libelle], _1[:path]] }
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

  class << self
    def champ_value(champ)
      champ.value.present? ? champ.value.to_s : champ_default_value
    end

    def champ_value_for_api(champ, version = 2)
      case version
      when 2
        champ_value(champ)
      else
        champ.value.presence || champ_default_api_value(version)
      end
    end

    def champ_value_for_export(champ, path = :value)
      path == :value ? champ.value.presence : champ_default_export_value(path)
    end

    def champ_value_for_tag(champ, path = :value)
      path == :value ? champ_value(champ) : nil
    end

    def champ_default_value
      ''
    end

    def champ_default_export_value(path = :value)
      nil
    end

    def champ_default_api_value(version = 2)
      case version
      when 2
        ''
      else
        nil
      end
    end
  end

  def columns(procedure_id:, displayable: true, prefix: nil)
    [
      Column.new(
        procedure_id:,
        table: Column::TYPE_DE_CHAMP_TABLE,
        column: stable_id.to_s,
        label: libelle_with_prefix(prefix),
        type: TypeDeChamp.filter_hash_type(type_champ),
        value_column: TypeDeChamp.filter_hash_value_column(type_champ),
        displayable:
      )
    ]
  end

  private

  def libelle_with_prefix(prefix)
    [prefix, libelle].compact.join(' – ')
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
end
