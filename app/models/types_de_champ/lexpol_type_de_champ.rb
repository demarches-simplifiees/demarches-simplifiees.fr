# frozen_string_literal: true

class TypesDeChamp::LexpolTypeDeChamp < TypesDeChamp::TypeDeChampBase
  class << self
    def champ_value_for_api(champ, version = 2)
      champ.value
    end

    def champ_value_for_export(champ, path = :value)
      champ.value
    end
  end

  def lexpol_mapping
    data && data['lexpol_mapping'] || ""
  end

  def lexpol_mapping=(value)
    self.data ||= {}
    self.data['lexpol_mapping'] = value
  end

  def lexpol_modele
    data && data['lexpol_modele'] || ""
  end

  def lexpol_modele=(value)
    self.data ||= {}
    self.data['lexpol_modele'] = value
  end
end
