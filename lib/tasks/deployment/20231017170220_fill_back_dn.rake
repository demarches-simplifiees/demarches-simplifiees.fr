# frozen_string_literal: true

namespace :after_party do
  desc 'Deployment task: Fill back DNs for procedure 2077'
  task fill_back_dn: :environment do
    puts "Running deploy task 'fill_back_dn'"

    DN_PATH = "storage/numeros_dn.json"
    next unless File.exist?(DN_PATH)

    numeros_dn = JSON.parse(File.read(DN_PATH))
    procedure_id = 2077

    progress = ProgressReport.new(1)
    repetitions = Champ.joins(dossier: :procedure)
      .where(type: "Champs::RepetitionChamp",
             dossiers: { procedure_revisions: { procedure_id: procedure_id } })
      .flat_map(&:rows)
    progress.inc
    progress.finish
    progress = ProgressReport.new(repetitions.count)

    repetitions.each do |row|
      champ_dn = champ(row, 'Numero DN')
      if champ_dn&.numero_dn.blank?
        key = "#{champ(row, "Nom de l'enfant")&.value}:#{champ(row, "Prénom de l'enfant")&.value}"
        if numeros_dn.key?(key)
          (dn, ddn) = numeros_dn[key].split(':')
          champ_dn.numero_dn = dn
          champ_dn.date_de_naissance = ddn
          champ_dn.save
        end
      end
      progress.inc
    end
    progress.finish

    # Update task as completed.  If you remove the line below, the task will
    # run with every deploy (or every time you call after_party:run).
    AfterParty::TaskRecord
      .create version: AfterParty::TaskRecorder.new(__FILE__).timestamp
  end

  def champ(row, label) = row.find { |c| c.type_de_champ.libelle == label }
end
