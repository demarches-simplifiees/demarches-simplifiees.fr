namespace :'2017_12_20_delete_old_administration' do
  task set: :environment do
    Administration.all.each do |a|
      puts "Deleting #{a.email}"
      a.destroy
    end
  end
end
