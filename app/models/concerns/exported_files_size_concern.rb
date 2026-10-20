# frozen_string_literal: true

# Sums the files a zip export or an archive ships for a set of dossiers, read
# off the blob sizes: the zip stores them uncompressed, so the sum is a
# faithful prediction of its size.
module ExportedFilesSizeConcern
  extend ActiveSupport::Concern

  # Size of the export-<id>.pdf that opens every dossier folder, measured on the
  # 84 k dossier PDFs stored in production (2026-09): p50 104 kB, p90 129 kB.
  DOSSIER_PDF_WEIGHT = 110.kilobytes

  private

  def exported_files_size(dossier_ids)
    attachments_size = exported_attachment_sources(dossier_ids).sum do |record_type, names, record_ids|
      exported_attachments_size(record_type, names, record_ids)
    end

    dossier_ids.size * DOSSIER_PDF_WEIGHT + attachments_size
  end

  # The attachments PiecesJustificativesService puts in an archive, by owner.
  # The archive skips titres d'identité: they are another champ type, so the
  # type filter leaves them out. It ships the current value of every champ: the
  # history streams keep their own copies of the pièces jointes they replaced.
  def exported_attachment_sources(dossier_ids)
    pj_champs = ChampData.where(type: Champs::PieceJustificativeChamp.to_s, stream: Dossier::MAIN_STREAM, dossier_id: dossier_ids)

    [
      ['Champ', 'piece_justificative_file', pj_champs.select(:id)],
      ['Commentaire', 'piece_jointe', Commentaire.where(dossier_id: dossier_ids).select(:id)],
      ['Dossier', 'justificatif_motivation', dossier_ids],
      ['Attestation', 'pdf', Attestation.where(dossier_id: dossier_ids).select(:id)],
      ['Avis', ['introduction_file', 'piece_justificative_file'], Avis.where(dossier_id: dossier_ids).select(:id)],
      ['Etablissement', ['entreprise_attestation_sociale', 'entreprise_attestation_fiscale'], Etablissement.where(dossier_id: dossier_ids).select(:id)],
    ]
  end

  # One query per owner keeps every plan a semi join on the attachments
  # uniqueness index; a single OR over the sources tempts the planner into a
  # scan of the whole table.
  def exported_attachments_size(record_type, names, record_ids)
    ActiveStorage::Attachment
      .joins(:blob)
      .where(record_type:, name: names, record_id: record_ids)
      # what the archive skips too: purged blobs, and blobs not (yet) scanned safe
      .where(active_storage_blobs: { soft_deleted_at: nil, virus_scan_result: ActiveStorage::VirusScanner::SAFE })
      .sum('active_storage_blobs.byte_size')
  end
end
