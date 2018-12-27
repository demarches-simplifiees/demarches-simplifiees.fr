class Champs::MultipleDropDownListChamp < Champ
  before_save :format_before_save

  def search_terms
    selected_options
  end

  def selected_options
    value.blank? ? [] : JSON.parse(value)
  end

  private

  def format_before_save
    if value.present?
      json = JSON.parse(value)
      if json == ['']
        self.value = nil
      else
        json = json - ['']
        self.value = json.to_s
      end
    end
  end

  def string_value
    selected_options.join(', ')
  end

  def value_for_export
    selected_options.join(', ')
  end
end
