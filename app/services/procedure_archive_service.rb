require 'tempfile'

class ProcedureArchiveService
  include Utils::Retryable
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
    if Flipper.enabled?(:zip_using_binary, @procedure)
      new_collect_files_archive(archive, instructeur)
    else
      old_collect_files_archive(archive, instructeur)
    end
  end

  def new_collect_files_archive(archive, instructeur)
    ## faux, ca ne doit prendre que certains groupe instructeur ?
    if archive.time_span_type == 'everything'
      dossiers = @procedure.dossiers.state_termine
    else
      dossiers = @procedure.dossiers.processed_in_month(archive.month)
    end

    attachments = create_list_of_attachments(dossiers)
    download_and_zip(attachments) do |zip_file|
      archive.file.attach(
        io: File.open(zip_file),
        filename: archive.filename(@procedure),
        # we don't want to run virus scanner on this file
        metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
      )
    end
    archive.make_available!
    InstructeurMailer.send_archive(instructeur, @procedure, archive).deliver_later
  end

  def old_collect_files_archive(archive, instructeur)
    if archive.time_span_type == 'everything'
      dossiers = @procedure.dossiers.state_termine
    else
      dossiers = @procedure.dossiers.processed_in_month(archive.month)
    end

    files = create_list_of_attachments(dossiers)

    tmp_file = Tempfile.new(['tc', '.zip'])

    Zip::OutputStream.open(tmp_file) do |zipfile|
      bug_reports = ''
      files.each do |attachment, pj_filename|
        zipfile.put_next_entry("#{zip_root_folder}/#{pj_filename}")
        begin
          zipfile.puts(attachment.download)
        rescue
          bug_reports += "Impossible de récupérer le fichier #{pj_filename}\n"
        end
      end
      if !bug_reports.empty?
        zipfile.put_next_entry("#{zip_root_folder}/LISEZMOI.txt")
        zipfile.puts(bug_reports)
      end
    end

    archive.file.attach(
      io: File.open(tmp_file),
      filename: archive.filename(@procedure),
      # we don't want to run virus scanner on this file
      metadata: { virus_scan_result: ActiveStorage::VirusScanner::SAFE }
    )
    tmp_file.delete
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

  def download_and_zip(attachments, &block)
    Dir.mktmpdir(nil, ARCHIVE_CREATION_DIR) do |tmp_dir|
      archive_dir = File.join(tmp_dir, zip_root_folder)
      zip_path = File.join(ARCHIVE_CREATION_DIR, "#{zip_root_folder}.zip")

      begin
        FileUtils.remove_entry_secure(archive_dir) if Dir.exist?(archive_dir)
        Dir.mkdir(archive_dir)

        bug_reports = ''
        attachments.each do |attachment, path|
          attachment_path = File.join(archive_dir, path)
          attachment_dir = File.dirname(attachment_path)

          FileUtils.mkdir_p(attachment_dir) if !Dir.exist?(attachment_dir)
          begin
            with_retry(max_attempt: 1) do
              ActiveStorage::DownloadableFile.download(attachment: attachment,
                                                       destination_path: attachment_path,
                                                       in_chunk: true)
            end
          rescue => e
            Rails.logger.error("Fail to download filename #{File.basename(attachment_path)} in procedure##{@procedure.id}, reason: #{e}")
            File.delete(attachment_path) if File.exist?(attachment_path)
            bug_reports += "Impossible de récupérer le fichier #{File.basename(attachment_path)}\n"
          end
        end

        if !bug_reports.empty?
          File.write(File.join(archive_dir, 'LISEZMOI.txt'), bug_reports)
        end

        File.delete(zip_path) if File.exist?(zip_path)
        puts `cd #{tmp_dir} && zip -r #{zip_path} #{zip_root_folder}`
        yield(zip_path)
      ensure
        FileUtils.remove_entry_secure(archive_dir) if Dir.exist?(archive_dir)
        File.delete(zip_path) if File.exist?(zip_path)
      end
    end
  end

  def zip_root_folder
    "procedure-#{@procedure.id}"
  end

  def create_list_of_attachments(dossiers)
    dossiers.flat_map do |dossier|
      ActiveStorage::DownloadableFile.create_list_from_dossier(dossier)
    end
  end

  def self.attachments_from_champs_piece_justificative(champs)
    champs
      .filter { |c| c.type_champ == TypeDeChamp.type_champs.fetch(:piece_justificative) }
      .filter { |pj| pj.piece_justificative_file.attached? }
      .map(&:piece_justificative_file)
  end

  def self.liste_pieces_justificatives_for_archive(dossier)
    champs_blocs_repetables = dossier.champs
      .filter { |c| c.type_champ == TypeDeChamp.type_champs.fetch(:repetition) }
      .flat_map(&:champs)

    attachments_from_champs_piece_justificative(champs_blocs_repetables + dossier.champs)
  end
end
