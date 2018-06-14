class Champs::MultipleDropDownListChamp < Champ
  before_save :format_before_save

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
