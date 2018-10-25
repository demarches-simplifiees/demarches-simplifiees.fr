require Rails.root.join("lib", "tasks", "task_helper")

namespace :'2018_01_18_clean_datetime_in_champs' do
  task clean: :environment do
    datetime_champs = TypeDeChamp.where(type_champ: "datetime").flat_map(&:champ)

    # Match " HH:MM" => nil a datetime is not valid if not composed by date AND time
    datetime_champs.select { |c| /^\s\d{2}:\d{2}$/.match(c.value) }.each do |c|
      rake_puts "cleaning #{c.value} => nil"
      c.update_columns(value: nil)
    end

    # Match "dd/mm/YYYY HH:MM" => "YYYY-mm-dd HH:MM"
    datetime_champs.select { |c| /^\d{2}\/\d{2}\/\d{4}\s\d{2}:\d{2}$/ =~ c.value }.each do |c|
      formated_date = Time.zone.strptime(c.value, "%d/%m/%Y %H:%M").strftime("%Y-%m-%d %H:%M")
      rake_puts "cleaning #{c.value} => #{formated_date}"
      c.update_columns(value: formated_date)
    end

    # Match "ddmmYYYY HH:MM" => "YYYY-mm-dd HH:MM"
    datetime_champs.select { |c| /^\d{8}\s\d{2}:\d{2}$/ =~ c.value }.each do |c|
      day = c.value[0,2]
      month = c.value[2,2]
      year = c.value[4,4]
      hours = c.value[9,2]
      minutes = c.value[12,2]
      formated_date = "#{year}-#{month}-#{day} #{hours}:#{minutes}"
      rake_puts "cleaning #{c.value} => #{formated_date}"
      c.update_columns(value: formated_date)
    end
  end
end
