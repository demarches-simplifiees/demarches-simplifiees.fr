class DropDownList < ApplicationRecord
  belongs_to :type_de_champ

  def options
    result = value.split(/[\r\n]|[\r]|[\n]|[\n\r]/).reject(&:empty?)
    result.blank? ? [] : [''] + result
  end
end
