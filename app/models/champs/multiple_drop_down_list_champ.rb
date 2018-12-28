class Champs::MultipleDropDownListChamp < Champ
  before_save :format_before_save

  def search_terms
    selected_options
  end

  def selected_options
    value.blank? ? [] : JSON.parse(value)
  end

  def to_s
    selected_options.join(', ')
  end

  def for_export
    value.present? ? selected_options.join(', ') : nil
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
end
