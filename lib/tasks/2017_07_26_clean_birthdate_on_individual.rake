require Rails.root.join("lib", "tasks", "task_helper")

namespace :'2017_07_26_clean_birthdate_on_individual' do
  task clean: :environment do
    # remove duplicates
    duplicate_individuals = Individual.group("dossier_id").count.select { |_dossier_id, count| count > 1 }.keys
    duplicate_individuals.each { |dossier_id| Individual.where(dossier_id: dossier_id, nom: nil).delete_all }

    # Match "" => nil
    Individual.where(birthdate: "").update_all(birthdate: nil)

    individuals_with_date = Individual.where.not(birthdate: nil)
    # Match 31/12/2017 => 2017-12-31
    individuals_with_date.select { |i| /^\d{2}\/\d{2}\/\d{4}$/.match(i.birthdate) }.each do |i|
      rake_puts "cleaning #{i.birthdate}"
      i.update(birthdate: Date.parse(i.birthdate).iso8601) rescue nil
    end

    # Match 31/12/17 => 2017-12-31
    individuals_with_date.select { |i| /^\d{2}\/\d{2}\/\d{2}$/.match(i.birthdate) }.each do |i|
      rake_puts "cleaning #{i.birthdate}"
      new_date = Date.strptime(i.birthdate, "%d/%m/%y")
      if new_date.year > 2017
        new_date = new_date - 100.years
      end
      i.update(birthdate: new_date.iso8601)
    end
  end
end
