class Champs::MultipleDropDownListChamp < Champ
  before_save :format_before_save

  def search_terms
    drop_down_list.selected_options(self)
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
    drop_down_list.selected_options(self).join(', ')
  end

  def value_for_export
    drop_down_list.selected_options(self).join(', ')
  end
end
