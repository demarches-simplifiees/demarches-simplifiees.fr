namespace :'2018_05_09_add_test_started_at_to_procedure' do
  task set: :environment do
    Procedure.publiees_ou_archivees.where(test_started_at: nil).find_each do |procedure|
      procedure.test_started_at = procedure.published_at
      procedure.save
    end
  end
end
