class DropDownList < ApplicationRecord
  belongs_to :type_de_champ

  def options
    result = value.split(/[\r\n]+/).reject(&:empty?)
    if result.blank?
      []
    else
      result.shift if 'autre'.casecmp(result.first).zero?
      [''] + result
    end
  end
end
