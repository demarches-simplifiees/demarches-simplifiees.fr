require 'tempfile'

class ProcedureArchiveService
  def initialize(procedure)
    @procedure = procedure
  end

  def make_and_upload_archive(archive)
    dossiers = Dossier.visible_by_administration
      .where(groupe_instructeur: archive.groupe_instructeurs)

    dossiers = if archive.time_span_type == 'everything'
      dossiers.state_termine
    else
      dossiers.processed_in_month(archive.month)
    end

    attachments = ActiveStorage::DownloadableFile.create_list_from_dossiers(dossiers)

    DownloadableFileService.download_and_zip(@procedure, attachments, zip_root_folder(archive)) do |zip_filepath|
      ArchiveUploader.new(procedure: @procedure, filename: archive.filename(@procedure), filepath: zip_filepath)
        .upload(archive)
    end
  end

  def self.procedure_files_size(procedure)
    dossiers_files_size(procedure.dossiers)
  end

  def self.dossiers_files_size(dossiers)
    dossiers.map do |dossier|
      liste_pieces_justificatives_for_archive(dossier).sum(&:byte_size)
    end.sum
  end

  private

  def zip_root_folder(archive)
    "procedure-#{@procedure.id}-#{archive.id}"
  end

  def self.attachments_from_champs_piece_justificative(champs)
    champs
      .filter { |c| c.type_champ == TypeDeChamp.type_champs.fetch(:piece_justificative) }
      .map(&:piece_justificative_file)
      .filter(&:attached?)
  end

  def self.liste_pieces_justificatives_for_archive(dossier)
    champs_blocs_repetables = dossier.champs
      .filter { |c| c.type_champ == TypeDeChamp.type_champs.fetch(:repetition) }
      .flat_map(&:champs)

    attachments_from_champs_piece_justificative(champs_blocs_repetables + dossier.champs)
  end
end
