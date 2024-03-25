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

  # all_ids = JSON.parse(File.read('success.log')).values.flatten
  # all_ids += JSON.parse(File.read('error.log')).values.flatten.reject{_1.is_a? String}
  desc <<~USAGE
    given a in_file path, read it as JSON
    the given file should be an Array of dossier_ids dump with JSON.dump `JSON.dump([1,2,3,4])`
    ex: rails recovery:list_blob_ids[/in_ids.json, /blob_keys.json]
  USAGE
  task :list_blob_ids, [:in_file_path, :out_file_path] => [:environment] do |_t, args|
    dossier_ids = JSON.parse(File.read(args[:in_file_path]))
    rake_puts "Will export #{dossier_ids}"

    dossiers_with_data = Dossier.where(id: dossier_ids)
      .preload(commentaires: { pieces_jointes_attachments: :blob },
                               avis: { introduction_file_attachment: :blob, piece_justificative_file_attachment: :blob },
                               dossier_operation_logs: { serialized_attachment: :blob },
                               attestation: { pdf_attachment: :blob },
                               justificatif_motivation_attachment: :blob)
    dossiers = DossierPreloader.new(dossiers_with_data)

    rake_puts "preloader rdy to batch"
    blob_keys = dossiers.in_batches(100).map do |dossier|
      rake_puts "working on dossier: #{dossier.id}"
      blob_keys_for_dossier = []

      blob_keys_for_dossier += dossier.champs.flat_map do |champ|
        champ.piece_justificative_file.map { _1.blob.key }
      end

      blob_keys_for_dossier += dossier.commentaires.flat_map do |commentaire|
        commentaire_blob_key = []
        if commentaire.piece_jointe.attached?
          commentaire_blob_key += [commentaire.piece_jointe_attachments.blob.key]
        end
        commentaire_blob_key
      end

      blob_keys_for_dossier += dossier.avis.flat_map do |avis|
        avis_blob_keys = []
        if avis.introduction_file.attached?
          avis_blob_keys += [avis.introduction_file_attachment.blob.key]
        end
        if avis.piece_justificative_file.attached?
          avis_blob_keys += [avis.piece_justificative_file.blob.key]
        end
        avis_blob_keys
      end

      blob_keys_for_dossier += dossier.dossier_operation_logs.flat_map do |dol|
        dol_blob_key = []
        if dol.serialized.attached?
          dol_blob_key += [dol.serialized_attachment.blob.key]
        end
        dol_blob_key
      end

      if dossier.attestation.present?
        blob_keys_for_dossier += [dossier.attestation.pdf.key]
      end

      if dossier.justificatif_motivation.attached?
        blob_keys_for_dossier += [dossier.justificatif_motivation_attachment.blob.key]
      end
      blob_keys_for_dossier
    end
    File.write(args[:out_file_path], JSON.dump(blob_keys))
  end
end
