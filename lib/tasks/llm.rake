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
      JSON.pretty_generate(completion[:operations].merge("summary" => completion[:summary]))
    )

    puts "Operations saved to tmp/procedure_#{procedure_id}_improvements.json"
  end

  task :lint_procedure, [:procedure_id] => :environment do |_t, args|
    procedure_id = args[:procedure_id]
    procedure = Procedure.includes(published_revision: { revision_types_de_champ_public: :type_de_champ })
      .find(procedure_id)

    procedure_linter = ProcedureLinter.new(procedure, procedure.published_revision)

    PP.pp "#{procedure_id}: rate: #{procedure_linter.rate}, error score: #{procedure_linter.score}"
    PP.pp procedure_linter.details
  end
end
