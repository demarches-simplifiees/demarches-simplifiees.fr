# frozen_string_literal: true

require "administrate/field/base"

class TypesDeChampCollectionField < Administrate::Field::Base
  def to_s
    data
  end
end
