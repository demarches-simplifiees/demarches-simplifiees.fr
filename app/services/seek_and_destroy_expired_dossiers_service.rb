class SeekAndDestroyExpiredDossiersService
  def self.action_dossier_brouillon
    # brouillon
    Dossier.send_brouillon_expiration_notices
    Dossier.destroy_brouillons_and_notify
  end

  def self.action_dossier_en_constuction
    # en_construction
    dossier_en_construction_expirant
    dossier_en_construction_expire
  end

  def self.dossier_en_construction_expirant
    Dossier.send_en_construction_expiration_notices_to_user

    expiring = Dossier
      .en_construction_close_to_expiration
      .en_construction_without_notice_sent

    traitement_dossier_expirant(expiring)
    expiring.update_all(en_construction_close_to_expiration_notice_sent_at: Time.zone.now)
  end

  def self.dossier_en_construction_expire
    Dossier.send_en_construction_destroy_notices_to_user

    expired = Dossier
      .expired_en_construction

    traitement_dossier_expire(expired)
  end

  private

  # #########################################
  # traitement des dossiers qui vont expirés dans 1 mois
  # #########################################
  def self.traitement_dossier_expirant(expiring)
    array_of_mail_near_deletion = []

    expiring.each do |dossier|
      destinataire = dossier.followers_instructeurs
      destinataire |= dossier.procedure.administrateurs
      add_mail_to_send(destinataire, dossier, array_of_mail_near_deletion)
    end

    # envoi des mails d'alerte de prochaine expiration des dossiers
    array_of_mail_near_deletion.each do |t|
      DossierMailer.notify_en_construction_near_deletion(t[:dest], t[:doss], false).deliver_later
    end
  end

  # #########################################
  # traitement des dossiers qui sont expirés
  # #########################################
  def self.traitement_dossier_expire(expired)
    dossier_to_remove = []
    array_of_mail_to_auto_deletion = []

    expired.each do |dossier|
      destinataire = dossier.followers_instructeurs
      destinataire |= dossier.procedure.administrateurs

      dossier_to_remove << dossier
      add_mail_to_send(destinataire, dossier, array_of_mail_to_auto_deletion)
    end

    # envoi des mails de suppression des dossiers
    array_of_mail_to_auto_deletion.each do |t|
      dossier_hashes = t[:doss].map(&:hash_for_deletion_mail)
      DossierMailer.notify_deletion(t[:dest], dossier_hashes).deliver_later
    end

    # supression des dossiers
    if !dossier_to_remove.empty?
      dossier_to_remove.each do |dossier|
        DeletedDossier.create_from_dossier(dossier)
        dossier.destroy
      end
    end
  end

  # ###############################
  # ajoute dans la liste des mails
  # ################################
  def self.add_mail_to_send(destinataires, dossier, tab)
    struct_of_mail_to_send = Struct.new(:dest, :doss)

    destinataires.each do |dest|
      stop = false
      tab.each do |current|
        if current[:dest].id == dest.id
          # un mail pour l'dest existe déjà
          if !current[:doss].include?(dossier)
            current[:doss] << dossier
          end
          stop = true
        end
      end

      if !stop
        # c'est un nouveau destinataire de mail
        list_dossier_new_mail = [dossier]
        new_structure_of_mail = [dest, list_dossier_new_mail]
        tab << struct_of_mail_to_send.new(*new_structure_of_mail)
      end
    end
  end
end
