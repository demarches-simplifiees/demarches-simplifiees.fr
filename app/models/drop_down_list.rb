class DropDownList < ApplicationRecord
  belongs_to :type_de_champ

  def options
    result = value.split(/[\r\n]|[\r]|[\n]|[\n\r]/).reject(&:empty?)
    result.blank? ? [] : [''] + result
  end

  def disabled_options
    options.select { |v| (v =~ /^--.*--$/).present? }
  end

  def multiple
    type_de_champ.type_champ == TypeDeChamp.type_champs.fetch(:multiple_drop_down_list)
  end
end
