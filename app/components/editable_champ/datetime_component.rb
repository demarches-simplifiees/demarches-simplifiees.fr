class EditableChamp::DatetimeComponent < ApplicationComponent
  def initialize(form:, champ:)
    @form, @champ = form, champ
  end

  def datetime_start_year(date)
    if date == nil || date.year == 0 || date.year >= Date.today.year - 1
      Date.today.year - 1
    else
      date.year
    end
  end
end
