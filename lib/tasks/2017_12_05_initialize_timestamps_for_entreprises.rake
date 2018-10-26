require Rails.root.join("lib", "tasks", "task_helper")

namespace :'2017_12_05_initialize_timestamps_for_entreprises' do
  task set: :environment do
    entreprises = Entreprise.where(created_at: nil).includes(:dossier)

    rake_puts "#{entreprises.count} to initialize..."

    entreprises.each { |e| initialize_entreprise(e) }
  end

  def initialize_entreprise(entreprise)
    rake_puts "initializing entreprise #{entreprise.id}"
    if entreprise.dossier.present?
      entreprise.update_columns(created_at: entreprise.dossier.created_at, updated_at: entreprise.dossier.created_at)
    else
      rake_puts "dossier #{entreprise.dossier_id} is missing for entreprise #{entreprise.id}"
      entreprise.update_columns(created_at: Time.zone.now, updated_at: Time.zone.now)
    end
  end
end
