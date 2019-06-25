namespace :'2019_05_29_migrate_commentaire_pj' do
  task run: :environment do
    commentaires = Commentaire.where
      .not(file: nil)
      .left_joins(:piece_jointe_attachment)
      .where('active_storage_attachments.id IS NULL')
      .order(:created_at)

    limit = ENV['LIMIT']
    if limit
      commentaires.limit!(limit.to_i)
    end

    progress = ProgressReport.new(commentaires.count)
    commentaires.find_each do |commentaire|
      if commentaire.file.present?
        uri = URI.parse(URI.escape(commentaire.file_url))
        response = Typhoeus.get(uri)
        if response.success?
          filename = commentaire.file.filename || commentaire.file_identifier
          updated_at = commentaire.updated_at
          dossier_updated_at = commentaire.dossier.updated_at
          commentaire.piece_jointe.attach(
            io: StringIO.new(response.body),
            filename: filename,
            content_type: commentaire.file.content_type,
            metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
          )
          commentaire.update_column(:updated_at, updated_at)
          commentaire.dossier.update_column(:updated_at, dossier_updated_at)
        end
      end
      progress.inc
    end
    progress.finish
  end
end
