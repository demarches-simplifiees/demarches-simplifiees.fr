require 'tempfile'

class ProcedureArchiveService
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
    if archive.time_span_type == 'everything'
      dossiers = @procedure.dossiers.state_termine
    else
      dossiers = @procedure.dossiers.processed_in_month(archive.month)
    end

    files = create_list_of_attachments(dossiers)

    tmp_file = Tempfile.new(['tc', '.zip'])

    Zip::OutputStream.open(tmp_file) do |zipfile|
      files.each do |attachment, pj_filename|
        zipfile.put_next_entry("procedure-#{@procedure.id}/#{pj_filename}")
        zipfile.puts(attachment.download)
      end
    end

    archive.file.attach(io: File.open(tmp_file), filename: archive.filename(@procedure))
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
