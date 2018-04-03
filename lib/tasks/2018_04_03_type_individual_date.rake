namespace :'2018_04_03_type_individual_date' do
  task set: :environment do
    Individual.all.each { |individual| save_birthdate_in_datetime_format(individual) }
  end

  def save_birthdate_in_datetime_format(individual)
    if individual.birthdate.present?
      begin
        individual.update_column(:second_birthdate, Date.parse(individual.birthdate))
      rescue
      end
    end
  end
end
