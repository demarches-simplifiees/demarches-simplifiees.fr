class DropDownList < ActiveRecord::Base
  belongs_to :type_de_champ

  def options
    result = value.split(/[\r\n]|[\r]|[\n]|[\n\r]/).reject(&:empty?)
    result.blank? ? [] : [''] + result
  end

  def disabled_options
    options.select{ |v| (v =~ /^--.*--$/).present? }
  end

  def selected_options(champ)
    champ.object.value.blank? ? [] : multiple ? JSON.parse(champ.object.value) : [champ.object.value]
  end

  def selected_options_without_decorator(champ)
    champ.value.blank? ? [] : multiple ? JSON.parse(champ.value) : [champ.value]
  end

  def multiple
    type_de_champ.type_champ == 'multiple_drop_down_list'
  end
end
