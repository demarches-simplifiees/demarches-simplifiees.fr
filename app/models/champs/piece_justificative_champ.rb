class Champs::PieceJustificativeChamp < Champ
  after_commit :create_virus_scan

  def create_virus_scan
    if self.piece_justificative_file&.attachment&.blob.present?
      VirusScan.where(champ: self).where.not(blob_key: self.piece_justificative_file.blob.key).delete_all
      VirusScan.find_or_create_by!(champ: self, blob_key: self.piece_justificative_file.blob.key) do |virus_scan|
        virus_scan.status = "pending"
      end
    end
  end
end
