require 'tempfile'

class ProcedureArchiveService
  ARCHIVE_CREATION_DIR = ENV.fetch('ARCHIVE_CREATION_DIR') { '/tmp' }

  def initialize(procedure)
    @procedure = procedure
  end

  def create_pending_archive(instructeur, type, month = nil)
    groupe_instructeurs = instructeur
      .groupe_instructeurs
      .where(procedure: @procedure)

    Archive.find_or_create_archive(type, month, groupe_instructeurs)
  end

  def collect_files_archive(archive, instructeur)
    dossiers = Dossier.visible_by_administration
      .where(groupe_instructeur: archive.groupe_instructeurs)

    dossiers = if archive.time_span_type == 'everything'
      dossiers.state_termine
    else
      dossiers.processed_in_month(archive.month)
    end

    attachments = create_list_of_attachments(dossiers)
    download_and_zip(archive, attachments) do |zip_filepath|
      ArchiveUploader.new(procedure: @procedure, archive: archive, filepath: zip_filepath)
        .upload
    end
    archive.make_available!
    InstructeurMailer.send_archive(instructeur, @procedure, archive).deliver_later
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

  def download_and_zip(archive, attachments, &block)
    Dir.mktmpdir(nil, ARCHIVE_CREATION_DIR) do |tmp_dir|
      archive_dir = File.join(tmp_dir, zip_root_folder(archive))
      zip_path = File.join(ARCHIVE_CREATION_DIR, "#{zip_root_folder(archive)}.zip")

      begin
        FileUtils.remove_entry_secure(archive_dir) if Dir.exist?(archive_dir)
        Dir.mkdir(archive_dir)

        download_manager = DownloadManager::ProcedureAttachmentsExport.new(@procedure, attachments, archive_dir)
        download_manager.download_all

        Dir.chdir(tmp_dir) do
          File.delete(zip_path) if File.exist?(zip_path)
          system 'zip', '-0', '-r', zip_path, zip_root_folder(archive)
        end
        yield(zip_path)
      ensure
        FileUtils.remove_entry_secure(archive_dir) if Dir.exist?(archive_dir)
        File.delete(zip_path) if File.exist?(zip_path)
      end
    end
  end

  def zip_root_folder(archive)
    "procedure-#{@procedure.id}-#{archive.id}"
  end

  def create_list_of_attachments(dossiers)
    dossiers.flat_map do |dossier|
      ActiveStorage::DownloadableFile.create_list_from_dossier(dossier)
    end
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
