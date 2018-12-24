class Champs::DatetimeChamp < Champ
  before_save :format_before_save

  def search_terms
    # Text search is pretty useless for datetimes so we’re not including these champs
  end

  private

  def format_before_save
    if (value =~ /=>/).present?
      self.value =
        begin
          hash_date = YAML.safe_load(value.gsub('=>', ': '))
          year, month, day, hour, minute = hash_date.values_at(1, 2, 3, 4, 5)
          Time.zone.local(year, month, day, hour, minute).strftime("%d/%m/%Y %H:%M")
        rescue
          nil
        end
    elsif /^\d{2}\/\d{2}\/\d{4}\s\d{2}:\d{2}$/.match?(value) # old browsers can send with dd/mm/yyyy hh:mm format
      self.value = Time.zone.strptime(value, "%d/%m/%Y %H:%M").strftime("%Y-%m-%d %H:%M")
    elsif !(/^\d{4}-\d{2}-\d{2}\s\d{2}:\d{2}$/.match?(value)) # a datetime not correctly formatted should not be stored
      self.value = nil
    end
  end
end
