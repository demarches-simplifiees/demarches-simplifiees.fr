require "administrate/field/base"

class ChampCollectionField < Administrate::Field::Base
  def to_s
    data
  end
end
