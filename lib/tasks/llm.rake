# frozen_string_literal: true

namespace :llm do
  desc 'Suggest an improved revision of a procedure'
  task :improve_procedure, [:procedure_id] => :environment do |_t, args|
    procedure_id = args[:procedure_id]
    procedure = Procedure.includes(published_revision: :revision_types_de_champ_public).find(procedure_id)

    llm = LLM::RevisionImproverService.new(procedure)
    completion = llm.suggest

    puts completion[:summary]

    # Écrit le fichier JSON
    File.write(
      "tmp/procedure_#{procedure_id}_improvements.json",
      JSON.pretty_generate(completion[:operations])
    )

    puts "Operations saved to tmp/procedure_#{procedure_id}_improvements.json"
  end
end
