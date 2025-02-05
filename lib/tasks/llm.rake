# frozen_string_literal: true

namespace :llm do
  desc 'Suggest an improved revision of a procedure'
  task :improve_procedure, [:procedure_id, :analysis] => :environment do |_t, args|
    procedure_id = args[:procedure_id]
    procedure = Procedure.includes(published_revision: :revision_types_de_champ_public).find(procedure_id)

    llm = LLM::RevisionImproverService.new(procedure)
    if args[:analysis].present?
      llm.now = args[:analysis].to_i
      analysis = File.read("tmp/llm/procedure_#{procedure_id}_#{args[:analysis]}_analysis.txt")
      llm.insert_analysis(analysis)
    else
      llm.analyze
    end

    completion = llm.suggest

    # Écrit le fichier JSON
    path = "tmp/llm/procedure_#{procedure_id}_#{llm.now}_suggestions.json"
    File.write(
      path,
      JSON.pretty_generate(completion)
    )

    puts "Operations saved to #{path}"
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
