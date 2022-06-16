class Logic::ChampValue < Logic::Term
  attr_reader :stable_id

  def initialize(stable_id)
    @stable_id = stable_id
  end

  def compute(champs)
    case type_de_champ.type_champ
    when all_types.fetch(:yes_no),
      all_types.fetch(:checkbox)
      champ(champs).true?
    when all_types.fetch(:integer_number), all_types.fetch(:decimal_number)
      champ(champs).for_api
    when all_types.fetch(:text)
      champ(champs).value
    end
  end

  def to_s = "#{type_de_champ.libelle} Nº#{stable_id}"

  def type
    case type_de_champ.type_champ
    when all_types.fetch(:yes_no),
      all_types.fetch(:checkbox)
      :boolean
    when all_types.fetch(:integer_number), all_types.fetch(:decimal_number)
      :number
    when all_types.fetch(:text)
      :string
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
      "op" => self.class.name,
      "stable_id" => @stable_id
    }
  end

  def self.from_h(h)
    self.new(h['stable_id'])
  end

  def ==(other)
    self.class == other.class && @stable_id == other.stable_id
  end

  private

  def type_de_champ
    TypeDeChamp.find_by(stable_id: stable_id)
  end

  def champ(champs)
    champs.find { |c| c.stable_id == stable_id }
  end

  def all_types
    TypeDeChamp.type_champs
  end
end
