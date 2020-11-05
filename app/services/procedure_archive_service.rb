require 'tempfile'

class ProcedureArchiveService
  def initialize(procedure)
    @procedure = procedure
  end

  def create_archive(instructeur, type, month = nil)
    groupe_instructeurs = instructeur
      .groupe_instructeurs
      .where(procedure: @procedure)

    if type == 'everything'
      dossiers = @procedure.dossiers.state_termine
      filename = "procedure-#{@procedure.id}.zip"
    else
      dossiers = @procedure.dossiers.termine_durant(month)
      filename = "procedure-#{@procedure.id}-mois-#{I18n.l(month, format: '%Y-%m')}.zip"
    end

    files = create_list_of_attachments(dossiers)

    archive = Archive.create(
      content_type: type,
      month: month,
      groupe_instructeurs: groupe_instructeurs
    )

    tmp_file = Tempfile.new(['tc', '.zip'])

    Zip::OutputStream.open(tmp_file) do |zipfile|
      # Les pièces justificatives
      files.each do |attachment, pj_filename|
        zipfile.put_next_entry(pj_filename)
        zipfile.puts(attachment.download)
      end

      # L'export PDF des dossier
      dossiers.each do |dossier|
        zipfile.put_next_entry("dossier-#{dossier.id}/dossier-#{dossier.id}.pdf")
        zipfile.puts(ApplicationController.render(template: 'dossiers/show',
                        formats: [:pdf],
                        assigns: {
                          include_infos_administration: false,
                          dossier: dossier
                        }))
      end
    end

    archive.file.attach(io: File.open(tmp_file), filename: filename)
    tmp_file.delete
    archive.make_available!
    InstructeurMailer.send_archive(instructeur, @procedure, archive).deliver_now
  end

  def self.poids_total_procedure(procedure)
    poids_total_dossiers(procedure.dossiers)
  end

  def self.poids_total_dossiers(dossiers)
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
