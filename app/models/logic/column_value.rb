# frozen_string_literal: true

class Logic::ColumnValue < Logic::Term
  delegate :stable_id, to: :@champ_column

  def initialize(champ_column)
    @champ_column = champ_column
  end

  def sources = [stable_id]

  def compute(champs)
    targeted_champ = champs.find { |champ| champ.stable_id == stable_id }
    @champ_column.value(targeted_champ)
  end

  def type(_type_de_champs) = @champ_column.type

  def options(_type_de_champs, _other = nil)
    result = @champ_column.options_for_select
    if result.present? && result.first.is_a?(String)
      result.map { |option| [option, option] }
    else
      result
    end
  end

  def errors(type_de_champs)
    if !type_de_champs.map(&:stable_id).include?(stable_id)
      [{ type: :not_available }]
    else
      []
    end
  end

  def to_h
    {
      "term" => self.class.name,
      "column_id" => @champ_column.id
    }
  end

  def self.from_h(h)
    column = Column.find(JSON.parse(h['column_id'], symbolize_names: true))
    self.new(column)
  end
end
