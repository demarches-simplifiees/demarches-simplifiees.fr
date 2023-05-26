namespace :recovery do
  desc <<~USAGE
    given a file path, read it as json data, preload dossier data and export to marshal.dump.
    the given file should be a json formatted as follow
      {
        procedure_id_1: [
          dossier_id_1,
          dossier_id_2,
          ...
        ],
        procedure_id_2: [
          ...
        ],
        ...
      }
    ex: rails recovery:export[missing_dossier_ids_per_procedure.json]
  USAGE
  task :export, [:file_path] => :environment do |_t, args|
    dossier_ids = JSON.parse(File.read(args[:file_path])).values.flatten
    rake_puts "Expecting to generate a dump with #{dossier_ids.size} dossiers"
    exporter = Recovery::Exporter.new(dossier_ids:)
    rake_puts "Found on db #{exporter.dossiers.size} dossiers"
    exporter.dump
    rake_puts "Export done, see: #{exporter.file_path}"
  end

  desc <<~USAGE
    given a file path, read it as marshal data
    the given file should be the result of recover:export
    ex: rails recovery:import[/absolute/path/to/lib/data/export.dump]
  USAGE
  task :import, [:file_path] => :environment do |_t, args|
    importer = Recovery::Importer.new(file_path: args[:file_path])
    rake_puts "Expecting to load  #{importer.dossiers.size} dossiers"
    importer.load
    rake_puts "Mise à jour terminée"
  end
end
