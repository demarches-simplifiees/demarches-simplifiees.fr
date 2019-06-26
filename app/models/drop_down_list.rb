class DropDownList < ApplicationRecord
  belongs_to :type_de_champ

  before_validation :clean_value

  def options
    result = value.split(/[\r\n]+/).reject(&:empty?)
    if result.blank?
      []
    else
      result.shift if 'autre'.casecmp(result.first).zero?
      [''] + result
    end
  end

  def disabled_options
    options.select { |v| (v =~ /^--.*--$/).present? }
  end

  def multiple
    type_de_champ.type_champ == TypeDeChamp.type_champs.fetch(:multiple_drop_down_list)
  end

  def allows_other_value?
    value =~ /^autre\s*[\n\r]/i
  end

  private

  def clean_value
    value = read_attribute(:value)
    value = value ? value.split("\r\n").map(&:strip).join("\r\n") : ''
    write_attribute(:value, value)
  end
end
