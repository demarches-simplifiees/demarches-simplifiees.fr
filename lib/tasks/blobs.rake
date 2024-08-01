# frozen_string_literal: true

namespace :blobs do
  desc <<~EOD
    given a file blob_ids.json with contains { blob_ids: [...] },
    download and reattached champ piece_justificative_file to create new blob
    and delete the old one, and thus, invalides old signed_ids.

    bin/rails 'blobs:renew_signed_ids[blob_ids.json]'
  EOD
  task :renew_signed_ids, [:file_path] => :environment do |_t, args|
    blob_ids = JSON.parse(File.read(args[:file_path]))['blob_ids']
    blobs = ActiveStorage::Blob.find(blob_ids)

    blobs.each do |blob|
      blob.open do |file|
        blob.attachments.each do |attachment|
          if [attachment.record_type, attachment.name] != ['Champ', 'piece_justificative_file']
            raise "not a piece justificative #{attachment.id}"
          end
          champ = attachment.record
          champ_updated_at = champ.updated_at
          dossier = champ.dossier
          dossier_updated_at = dossier.updated_at

          file.rewind

          # badly, it updates champ and dossier updated_at attributes
          champ.piece_justificative_file.attach(io: file, filename: blob.filename, content_type: blob.content_type)
          # it destroys the blob as well
          attachment.destroy

          champ.update_column(:updated_at, champ_updated_at)
          dossier.update_column(:updated_at, dossier_updated_at)
        end
      end
    end
  end
end
