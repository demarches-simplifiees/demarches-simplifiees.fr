# frozen_string_literal: true

module Types
  class Order < Types::BaseEnum
    value('ASC', 'L’ordre ascendant.', value: :asc)
    value('DESC', 'L’ordre descendant.', value: :desc)
  end
end
