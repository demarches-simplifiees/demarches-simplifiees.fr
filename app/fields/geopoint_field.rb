require "administrate/field/base"

class GeopointField < Administrate::Field::Base
  def lat
    data.first
  end

  def lng
    data.last
  end
end
