class ChampProjection
  include ChampConditionalConcern

  def initialize(dossier, type_de_champ, champ: nil, row_id: nil)
    @dossier = dossier
    @type_de_champ = type_de_champ
    @champ = champ
    @row_id = row_id
  end

  attr_reader :dossier, :type_de_champ, :row_id
  delegate :libelle, :type_champ, :stable_id, to: :type_de_champ
  delegate :piece_justificative?, :repetition?, :header_section?, :exclude_from_view?, to: :type_de_champ

  def champ
    if @champ.present? && @champ.type == "Champs::#{type_champ.classify}Champ"
      @champ
    end
  end

  def html_id
    row_id.present? ? "champ-#{stable_id}-#{row_id}" : "champ-#{stable_id}"
  end

  def input_group_id
    html_id
  end

  def input_id
    "#{html_id}-input"
  end

  def children
    if repetition?
      dossier.revision.children_of(type_de_champ)
    else
      []
    end
  end

  def row_ids
    if repetition? && champ.present?
      champ.row_ids
    else
      []
    end
  end

  def level
    type_de_champ.level_for_revision(dossier.revision) if header_section?
  end

  def champ_blank?
    champ.blank?
  end

  def to_key
    [stable_id]
  end

  def model_name
    type_de_champ.model_name
  end
end
