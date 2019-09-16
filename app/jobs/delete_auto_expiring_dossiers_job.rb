class DeleteAutoExpiringDossiersJob < ApplicationJob
  queue_as :cron

  def perform(*args)
    @array_of_mail_near_deletion = []
    @array_of_mail_to_auto_deletion = []
    @array_of_mail_excuse_deletion = []

    remove_dossier_hidden

    action_dossier_before_instuction(Dossier.states.fetch(:brouillon))
    action_dossier_before_instuction(Dossier.states.fetch(:en_construction))
    action_dossier_before_instuction(Dossier.states.fetch(:en_instruction))

    # envoi des mails d'alerte de prochaine expiration des dossiers
    @array_of_mail_near_deletion.each do |t|
      DossierMailer.notify_near_deletion(t[:message_doss], t[:email]).deliver_later
    end

    # envoi des mails de suppression des dossiers
    @array_of_mail_to_auto_deletion.each do |t|
      DossierMailer.notify_auto_deletion_to(t[:doss], t[:email]).deliver_later
    end

    # envoi des mails d'excuse pour la supression des dossiers
    @array_of_mail_excuse_deletion.each do |t|
      DossierMailer.notify_excuse_deletion_to_user(t[:doss], t[:email]).deliver_later
    end
  end

  def action_dossier_before_instuction(status)
    case status
    when Dossier.states.fetch(:brouillon)
      expired, expiring = Dossier
        .includes(:procedure)
        .state_brouillon
        .nearing_end_of_brouillon
        .partition(&:brouillon_expired?)

    when Dossier.states.fetch(:en_construction)
      expired, expiring = Dossier
        .includes(:procedure)
        .state_en_construction
        .nearing_end_of_construction
        .partition(&:construction_expired?)

    when Dossier.states.fetch(:en_instruction)
      expired, expiring = Dossier
        .includes(:procedure)
        .state_en_instruction
        .nearing_end_of_instruction
        .partition(&:instruction_expired?)

    end

    traitement_dossier_expirant(expiring, status)
    traitement_dossier_expire(expired, status)
  end

  # recherche l'instructeur du dossier courant
  def find_instructeur_email_for_dossier(dossier)
    return dossier.followers_instructeurs.pluck(:email)
  end

  # recherche l'administarteur du dossier courant
  def find_administrateur_email_for_dossier(dossier)
    return dossier.procedure.administrateurs.pluck(:email)
  end

  # suppression de tous les dossiers expirés à l'état hidden
  def remove_dossier_hidden
    to_remove = Dossier.all.unscoped.hidden
    remove_list = []

    to_remove.each do |dossier|
      date_suppression = dossier.hidden_at + 1.month

      if date_suppression <= Time.zone.now
        remove_list << dossier.id
      end
    end

    if !remove_list.empty?
      Dossier.delete_dossier_from_base(remove_list)
    end
  end

  # #########################################
  # traitement des dossiers qui sont expirés
  # #########################################
  def traitement_dossier_expire(expired, status)
    dossier_to_remove = []

    expired.each do |dossier|
      duree = dossier.procedure.duree_conservation_dossiers_dans_ds
      destinataire_mail = []
      user_mail = []

      case status
      when Dossier.states.fetch(:brouillon)
        date = dossier.created_at
        destinataire_mail << dossier.user.email

      when Dossier.states.fetch(:en_construction)
        user_mail << dossier.user.email
        date = dossier.en_construction_at
        destinataire_mail |= find_instructeur_email_for_dossier(dossier)
        destinataire_mail |= find_administrateur_email_for_dossier(dossier)

      when Dossier.states.fetch(:en_instruction)
        user_mail << dossier.user.email
        date = dossier.en_instruction_at
        destinataire_mail |= find_instructeur_email_for_dossier(dossier)
        destinataire_mail |= find_administrateur_email_for_dossier(dossier)

      end

      date_suppression = date + duree.months + 5.days

      if date_suppression <= Time.zone.now
        dossier_to_remove << dossier.id

        # les brouillons dont la date de ceation est inferieur au 01-2019 sont supprimé sans envoi de mail
        if ((status != Dossier.states.fetch(:brouillon)) || date >= Date.parse('01-01-2019'))
          add_mail_delete_to_send(destinataire_mail, dossier, @array_of_mail_to_auto_deletion)
          add_mail_delete_to_send(user_mail, dossier, @array_of_mail_excuse_deletion)
        end
      end
    end

    # supression des dossiers
    if !dossier_to_remove.empty?
      Dossier.delete_dossier_from_base(dossier_to_remove)
    end
  end

  # #########################################
  # traitement des dossiers qui vont expirer dans 1 mois
  # #########################################
  def traitement_dossier_expirant(expiring, status)
    expiring.each do |dossier|
      duree = dossier.procedure.duree_conservation_dossiers_dans_ds

      case status
      when Dossier.states.fetch(:brouillon)
        date = dossier.created_at
      when Dossier.states.fetch(:en_construction)
        date = dossier.en_construction_at
      when Dossier.states.fetch(:en_instruction)
        date = dossier.en_instruction_at
      end

      date_suppression = date + duree.months
      date_message = date_suppression - 1.month
      time = Time.zone.now

      if (date_message.year == time.year &&
        date_message.month == time.month &&
        date_message.day == time.day)

        # regroupement par destinataire du mail, des dossiers qui vont prochainement expiré
        if (status == Dossier.states.fetch(:brouillon))
          add_mail_to_send([dossier.user.email], dossier, date_suppression, 'DOSSIER qui concerne la procedure \'PROC\', doit être déposé avant le DATE, sinon il sera supprimé', @array_of_mail_near_deletion)
        else
          # recherche de l'email de l'instructeur et des administrateur qui suivent le dossier
          destinataire_email = find_instructeur_email_for_dossier(dossier)
          destinataire_email |= find_administrateur_email_for_dossier(dossier)

          add_mail_to_send(destinataire_email, dossier, date_suppression, 'DOSSIER qui concerne la procedure \'PROC\', doit être traité avant le DATE', @array_of_mail_near_deletion)
        end
      end
    end
  end

  # ############################################################
  # ajoute dans la liste des mails de suppression dans 1 mois
  # ############################################################
  def add_mail_to_send(destinataire_email, dossier, date_suppression, message, tab_mail)
    struct_of_mail_to_send = Struct.new(:email, :message_doss)

    message_dossier = message.sub! 'DOSSIER', dossier.id.to_s
    message_dossier = message_dossier.sub! 'PROC', dossier.procedure.libelle
    message_dossier = message_dossier.sub! 'DATE', date_suppression.at_midnight().to_s

    destinataire_email.each do |dest_mail|
      stop = false
      tab_mail.each do |current|
        if current[:email] == dest_mail
          # un mail pour l'dest_email' existe déjà
          current[:message_doss] << message_dossier
          stop = true
        end
      end

      if !stop
        # c'est un nouveau destinataire de mail
        list_message_new_mail = []
        list_message_new_mail << message_dossier
        new_structure_of_mail = [dest_mail, list_message_new_mail]
        tab_mail << struct_of_mail_to_send.new(*new_structure_of_mail)
      end
    end
  end

  # #######################################################
  # ajoute dans la liste des mails de suppression immediat
  # #######################################################
  def add_mail_delete_to_send(destinataire_email, dossier, tab_mail)
    struct_of_mail_to_send = Struct.new(:email, :doss)

    destinataire_email.each do |dest_mail|
      stop = false
      tab_mail.each do |current|
        if current[:email] == dest_mail
          # un mail pour l'dest_mail existe déjà
          current[:doss] << dossier
          stop = true
        end
      end

      if !stop
        # c'est un nouveau destinataire de mail
        list_dossier_new_mail = [dossier]
        new_structure_of_mail = [dest_mail, list_dossier_new_mail]
        tab_mail << struct_of_mail_to_send.new(*new_structure_of_mail)
      end
    end
  end
end
