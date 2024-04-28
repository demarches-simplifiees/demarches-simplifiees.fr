# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: force_dossiers_to_fill_missing_individual'
  task force_dossiers_to_fill_missing_individual: :environment do
    puts "Running deploy task 'force_dossiers_to_fill_missing_individual'"

    # Corrige 11 dossiers qui ont profité d'un bug les 25-26 avril 2023 pour être créés avec des noms vides
    # et qui empêche de terminer le dossier.
    # Les dossiers seront repasses manuellement en construction et les usagers informés par la messagerie
    # pour que tout l'historique soit loggué et que les instructeurs soient aussi prévenus.
    dossiers = Dossier.joins(:individual)
      .where(individual: { nom: nil })
      .state_en_construction_ou_instruction
      .includes(:procedure)

    dossiers.find_each do |dossier|
      rake_puts "Dossier id=#{dossier.id} procedure_id=#{dossier.procedure.id} procedure=#{dossier.procedure.libelle}"

      dossier.autorisation_donnees = false
      dossier.save!(validate: false)
    end

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end
end
