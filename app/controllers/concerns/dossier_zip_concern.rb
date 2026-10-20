# frozen_string_literal: true

module DossierZipConcern
  extend ActiveSupport::Concern

  private

  def stream_dossier_zip(dossier, user_profile)
    files = ActiveStorage::DownloadableFile.create_list_from_dossiers(dossiers: Dossier.where(id: dossier.id), user_profile:)
    cleaned_files = ActiveStorage::DownloadableFile.cleanup_list_from_dossier(files)

    zip_kit_stream(filename: "dossier-#{dossier.id}.zip") do |zip|
      ActiveStorage::DownloadableFile.write_to_zip(zip, cleaned_files)
    end
  end
end
