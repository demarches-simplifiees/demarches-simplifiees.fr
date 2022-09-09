class Logic::ChampValue < Logic::Term
  MANAGED_TYPE_DE_CHAMP = TypeDeChamp.type_champs.slice(
    :yes_no,
    :checkbox,
    :integer_number,
    :decimal_number,
    :drop_down_list,
    :multiple_drop_down_list
  )

  CHAMP_VALUE_TYPE = {
    boolean: :boolean,
    number: :number,
    enum: :enum,
    enums: :enums,
    empty: :empty,
    unmanaged: :unmanaged
  }

  attr_reader :stable_id

  def initialize(stable_id)
    @stable_id = stable_id
  end

  def compute(champs)
    targeted_champ = champ(champs)

    return nil if !targeted_champ.visible?
    return nil if targeted_champ.blank?

    case type_de_champ.type_champ
    when MANAGED_TYPE_DE_CHAMP.fetch(:yes_no),
      MANAGED_TYPE_DE_CHAMP.fetch(:checkbox)
      targeted_champ.true?
    when MANAGED_TYPE_DE_CHAMP.fetch(:integer_number), MANAGED_TYPE_DE_CHAMP.fetch(:decimal_number)
      targeted_champ.for_api
    when MANAGED_TYPE_DE_CHAMP.fetch(:drop_down_list)
      targeted_champ.selected
    when MANAGED_TYPE_DE_CHAMP.fetch(:multiple_drop_down_list)
      targeted_champ.selected_options
    end
  end

  def to_s = type_de_champ&.libelle # TODO: gerer le cas ou un tdc est supprimé

  def type
    case type_de_champ&.type_champ # TODO: gerer le cas ou un tdc est supprimé
    when MANAGED_TYPE_DE_CHAMP.fetch(:yes_no),
      MANAGED_TYPE_DE_CHAMP.fetch(:checkbox)
      CHAMP_VALUE_TYPE.fetch(:boolean)
    when MANAGED_TYPE_DE_CHAMP.fetch(:integer_number), MANAGED_TYPE_DE_CHAMP.fetch(:decimal_number)
      CHAMP_VALUE_TYPE.fetch(:number)
    when MANAGED_TYPE_DE_CHAMP.fetch(:drop_down_list)
      CHAMP_VALUE_TYPE.fetch(:enum)
    when MANAGED_TYPE_DE_CHAMP.fetch(:multiple_drop_down_list)
      CHAMP_VALUE_TYPE.fetch(:enums)
    else
      CHAMP_VALUE_TYPE.fetch(:unmanaged)
    end
  end

  def errors(stable_ids)
    if !stable_ids.include?(stable_id)
      ["le type de champ stable_id=#{stable_id} n'est pas disponible"]
    else
      []
    end
  end

  def to_h
    {
      "term" => self.class.name,
      "stable_id" => @stable_id
    }
  end

  def self.from_h(h)
    self.new(h['stable_id'])
  end

  def ==(other)
    self.class == other.class && @stable_id == other.stable_id
  end

  def options
    opts = type_de_champ.drop_down_list_enabled_non_empty_options.map { |option| [option, option] }
    if type_de_champ.drop_down_other?
      opts + [["Autre", Champs::DropDownListChamp::OTHER]]
    else
      opts
    end
  end

  private

  def type_de_champ
    TypeDeChamp.find_by(stable_id: stable_id)
  end

  def champ(champs)
    champs.find { |c| c.stable_id == stable_id }
  end
end
