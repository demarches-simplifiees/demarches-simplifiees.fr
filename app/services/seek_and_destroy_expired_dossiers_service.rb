class SeekAndDestroyExpiredDossiersService
  def self.action_dossier_brouillon
    Dossier.send_brouillon_expiration_notices
    Dossier.destroy_brouillons_and_notify
  end

  def self.action_dossier_en_constuction
    dossier_en_construction_expirant
  end

  def self.dossier_en_construction_expirant
    Dossier.send_en_construction_expiration_notices_to_user

    expiring = Dossier
      .en_construction_close_to_expiration
      .en_construction_without_notice_sent

    Dossier.traitement_dossier_expirant(expiring)
    expiring.update_all(en_construction_close_to_expiration_notice_sent_at: Time.zone.now)
  end
end
