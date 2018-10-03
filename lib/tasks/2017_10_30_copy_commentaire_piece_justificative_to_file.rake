require Rails.root.join("lib", "tasks", "task_helper")

namespace :'2017_10_30_copy_commentaire_piece_justificative_to_file' do
  task set: :environment do
    commentaires_to_process = Commentaire.where(file: nil).where.not(piece_justificative_id: nil).reorder(id: :desc)

    rake_puts "#{commentaires_to_process.count} commentaires to process..."

    commentaires_to_process.each do |c|
      process_commentaire(c)
    end
  end

  task fix: :environment do
    commentaires_to_fix = Commentaire.where.not(file: nil).where.not(piece_justificative_id: nil).reorder(id: :desc)

    rake_puts "#{commentaires_to_fix.count} commentaires to fix..."

    commentaires_to_fix.each do |c|
      process_commentaire(c)
    end
  end

  def sanitize_name(name) # from https://github.com/carrierwaveuploader/carrierwave/blob/master/lib/carrierwave/sanitized_file.rb#L323
    name = name.gsub(/[^[:word:]\.\-\+]/,"_")
    name = "_#{name}" if name.match?(/\A\.+\z/)
    name = "unnamed" if name.empty?
    return name.mb_chars.to_s
  end

  def process_commentaire(commentaire)
    rake_puts "Processing commentaire #{commentaire.id}"
    if commentaire.piece_justificative.present?
      # https://github.com/carrierwaveuploader/carrierwave#uploading-files-from-a-remote-location
      commentaire.remote_file_url = commentaire.piece_justificative.content_url

      if commentaire.piece_justificative.original_filename.present?
        commentaire.file.define_singleton_method(:filename) { sanitize_name(commentaire.piece_justificative.original_filename) }
      end

      if commentaire.body.blank?
        commentaire.body = commentaire.piece_justificative.original_filename || "."
      end

      commentaire.save
      if commentaire.file.blank?
        rake_puts "Failed to save file for commentaire #{commentaire.id}"
      end
    end
  end
end
