# frozen_string_literal: true

module DossierStateConcern
  extend ActiveSupport::Concern

  def submit_en_construction!
    self.traitements.submit_en_construction
    save!

    RoutingEngine.compute(self)

    resolve_pending_correction!
    process_sva_svr!
    clean_champs_after_submit!
  end

  def after_passer_en_construction
    self.conservation_extension = 0.days
    self.depose_at = self.en_construction_at = self.traitements
      .passer_en_construction
      .processed_at
    self.expired_at = expiration_date

    save!

    RoutingEngine.compute(self)

    MailTemplatePresenterService.create_commentaire_for_state(self, Dossier.states.fetch(:en_construction))
    procedure.compute_dossiers_count

    process_declarative!
    process_sva_svr!

    index_search_terms_later
  end

  def after_commit_passer_en_construction
    NotificationMailer.send_en_construction_notification(self).deliver_later
    NotificationMailer.send_notification_for_tiers(self).deliver_later if self.for_tiers?
    groupe_instructeur.instructeurs.with_instant_email_dossier_notifications.each do |instructeur|
      DossierMailer.notify_new_dossier_depose_to_instructeur(self, instructeur.email).deliver_later
    end

    clean_champs_after_submit!
  end

  def after_passer_en_instruction(h)
    instructeur = h[:instructeur]
    instructeur.follow(self)

    self.en_construction_close_to_expiration_notice_sent_at = nil
    self.conservation_extension = 0.days
    self.en_instruction_at = self.traitements
      .passer_en_instruction(instructeur: instructeur)
      .processed_at
    self.expired_at = nil

    save!

    reset_user_buffer_stream!
    MailTemplatePresenterService.create_commentaire_for_state(self, Dossier.states.fetch(:en_instruction))
    resolve_pending_correction!

    log_dossier_operation(instructeur, :passer_en_instruction)
  end

  def after_commit_passer_en_instruction(h)
    disable_notification = h.fetch(:disable_notification, false)

    if !disable_notification
      NotificationMailer.send_en_instruction_notification(self).deliver_later
      NotificationMailer.send_notification_for_tiers(self).deliver_later if self.for_tiers?
    end

    # TODO remove when all forks are gone
    editing_forks.each(&:destroy_editing_fork!)
  end

  def after_passer_automatiquement_en_instruction
    self.en_construction_close_to_expiration_notice_sent_at = nil
    self.conservation_extension = 0.days
    self.en_instruction_at = traitements.passer_en_instruction.processed_at
    self.expired_at = nil

    if procedure.declarative_en_instruction?
      self.declarative_triggered_at = en_instruction_at
    end

    save!

    MailTemplatePresenterService.create_commentaire_for_state(self, Dossier.states.fetch(:en_instruction))

    if procedure.sva_svr_enabled?
      log_automatic_dossier_operation(:passer_en_instruction, self)
    else
      log_automatic_dossier_operation(:passer_en_instruction)
    end
  end

  def after_commit_passer_automatiquement_en_instruction
    NotificationMailer.send_en_instruction_notification(self).deliver_later
    NotificationMailer.send_notification_for_tiers(self).deliver_later if self.for_tiers?
    DossierNotification.destroy_notifications_by_dossier_and_type(self, :dossier_depose)
  end

  def after_repasser_en_construction(h)
    instructeur = h[:instructeur]

    create_missing_traitemets

    self.en_construction_close_to_expiration_notice_sent_at = nil
    self.conservation_extension = 0.days
    self.en_construction_at = self.traitements
      .passer_en_construction(instructeur: instructeur)
      .processed_at
    self.expired_at = expiration_date

    save!

    log_dossier_operation(instructeur, :repasser_en_construction)
  end

  def after_commit_repasser_en_construction
  end

  def after_accepter(h)
    instructeur = h[:instructeur]
    motivation = h[:motivation]
    justificatif = h[:justificatif]

    self.processed_at = self.traitements
      .accepter(motivation: motivation, instructeur: instructeur)
      .processed_at
    self.expired_at = expiration_date

    save!

    if justificatif
      self.justificatif_motivation.attach(justificatif)
    end

    if attestation.nil?
      self.attestation = build_attestation
    end

    save!

    MailTemplatePresenterService.create_commentaire_for_state(self, Dossier.states.fetch(:accepte))

    log_dossier_operation(instructeur, :accepter, self)
  end

  def after_commit_accepter(h)
    disable_notification = h.fetch(:disable_notification, false)

    if !disable_notification
      if procedure.accuse_lecture?
        NotificationMailer.send_accuse_lecture_notification(self).deliver_later
      else
        NotificationMailer.send_accepte_notification(self).deliver_later
      end
      NotificationMailer.send_notification_for_tiers(self).deliver_later if self.for_tiers?
    end

    send_dossier_decision_to_experts(self)
    clean_champs_after_instruction!
  end

  def after_accepter_automatiquement
    self.processed_at = traitements.accepter_automatiquement.processed_at
    self.expired_at = expiration_date

    if procedure.declarative_accepte?
      self.en_instruction_at = self.processed_at
      self.declarative_triggered_at = self.processed_at
    elsif procedure.sva?
      self.sva_svr_decision_triggered_at = self.processed_at
    end

    save!

    if attestation.nil?
      self.attestation = build_attestation
    end

    save!

    MailTemplatePresenterService.create_commentaire_for_state(self, Dossier.states.fetch(:accepte))

    log_automatic_dossier_operation(:accepter, self)
  end

  def after_commit_accepter_automatiquement
    if procedure.accuse_lecture?
      NotificationMailer.send_accuse_lecture_notification(self).deliver_later
    else
      NotificationMailer.send_accepte_notification(self).deliver_later
    end
    NotificationMailer.send_notification_for_tiers(self).deliver_later if self.for_tiers?

    send_dossier_decision_to_experts(self)
    clean_champs_after_instruction!
  end

  def after_refuser(h)
    instructeur = h[:instructeur]
    motivation = h[:motivation]
    justificatif = h[:justificatif]

    self.processed_at = self.traitements
      .refuser(motivation: motivation, instructeur: instructeur)
      .processed_at
    self.expired_at = expiration_date

    save!

    if justificatif
      self.justificatif_motivation.attach(justificatif)
    end

    save!

    MailTemplatePresenterService.create_commentaire_for_state(self, Dossier.states.fetch(:refuse))

    log_dossier_operation(instructeur, :refuser, self)
  end

  def after_commit_refuser(h)
    disable_notification = h.fetch(:disable_notification, false)

    if !disable_notification
      if procedure.accuse_lecture?
        NotificationMailer.send_accuse_lecture_notification(self).deliver_later
      else
        NotificationMailer.send_refuse_notification(self).deliver_later
      end
      NotificationMailer.send_notification_for_tiers(self).deliver_later if self.for_tiers?
    end

    send_dossier_decision_to_experts(self)
    clean_champs_after_instruction!
  end

  def after_refuser_automatiquement
    # Only SVR can refuse automatically
    I18n.with_locale(user.locale || I18n.default_locale) do
      self.motivation = I18n.t("shared.dossiers.motivation.refused_by_svr")
    end

    self.processed_at = traitements.refuser_automatiquement(motivation:).processed_at
    self.sva_svr_decision_triggered_at = self.processed_at
    self.expired_at = expiration_date

    save!

    MailTemplatePresenterService.create_commentaire_for_state(self, Dossier.states.fetch(:refuse))

    log_automatic_dossier_operation(:refuser, self)
  end

  def after_commit_refuser_automatiquement
    if procedure.accuse_lecture?
      NotificationMailer.send_accuse_lecture_notification(self).deliver_later
    else
      NotificationMailer.send_refuse_notification(self).deliver_later
    end
    NotificationMailer.send_notification_for_tiers(self).deliver_later if self.for_tiers?

    send_dossier_decision_to_experts(self)
    clean_champs_after_instruction!
  end

  def after_classer_sans_suite(h)
    instructeur = h[:instructeur]
    motivation = h[:motivation]
    justificatif = h[:justificatif]

    self.processed_at = self.traitements
      .classer_sans_suite(motivation: motivation, instructeur: instructeur)
      .processed_at
    self.expired_at = expiration_date

    save!

    if justificatif
      self.justificatif_motivation.attach(justificatif)
    end

    save!

    MailTemplatePresenterService.create_commentaire_for_state(self, Dossier.states.fetch(:sans_suite))

    log_dossier_operation(instructeur, :classer_sans_suite, self)
  end

  def after_commit_classer_sans_suite(h)
    disable_notification = h.fetch(:disable_notification, false)

    if !disable_notification
      if procedure.accuse_lecture?
        NotificationMailer.send_accuse_lecture_notification(self).deliver_later
      else
        NotificationMailer.send_sans_suite_notification(self).deliver_later
      end
      NotificationMailer.send_notification_for_tiers(self).deliver_later if self.for_tiers?
    end

    send_dossier_decision_to_experts(self)
    clean_champs_after_instruction!
  end

  def after_repasser_en_instruction(h)
    instructeur = h[:instructeur]

    create_missing_traitemets

    self.hidden_by_user_at = nil
    self.archived = false
    self.termine_close_to_expiration_notice_sent_at = nil
    self.conservation_extension = 0.days
    self.en_instruction_at = self.traitements
      .passer_en_instruction(instructeur: instructeur)
      .processed_at
    self.expired_at = nil
    attestation&.destroy

    self.sva_svr_decision_on = nil
    self.motivation = nil
    self.justificatif_motivation.purge_later

    save!

    MailTemplatePresenterService.create_commentaire_for_state(self, DossierOperationLog.operations.fetch(:repasser_en_instruction))

    log_dossier_operation(instructeur, :repasser_en_instruction)
  end

  def after_commit_repasser_en_instruction(h)
    disable_notification = h.fetch(:disable_notification, false)

    if !disable_notification
      NotificationMailer.send_repasser_en_instruction_notification(self).deliver_later
      NotificationMailer.send_notification_for_tiers(self, repasser_en_instruction: true).deliver_later if self.for_tiers?
    end

    rebase_later
  end

  def clean_champs_after_submit!
    remove_discarded_rows!
    remove_not_visible_rows!
    remove_not_visible_or_empty_champs!
    # TODO remove when all forks are gone
    editing_forks.each(&:destroy_editing_fork!)
  end

  def clean_champs_after_instruction!
    remove_discarded_rows!
    remove_titres_identite!
  end

  private

  def remove_discarded_rows!
    row_to_remove_ids = champs.filter { _1.row? && _1.discarded? }.map(&:row_id)

    return if row_to_remove_ids.empty?
    champs.where(row_id: row_to_remove_ids).destroy_all
  end

  def remove_not_visible_or_empty_champs!
    repetition_to_keep_stable_ids, champ_to_keep_public_ids = project_champs_public_all
      .reject { _1.blank? || !_1.visible? }
      .partition(&:repetition?)
      .then { |(repetitions, champs)| [repetitions.to_set(&:stable_id), champs.to_set(&:public_id)] }

    rows_public, champs_public = champs
      .filter(&:public?)
      .partition(&:row?)

    champs_to_remove = champs_public.reject { champ_to_keep_public_ids.member?(_1.public_id) }
    champs_to_remove += rows_public.reject { repetition_to_keep_stable_ids.member?(_1.stable_id) }

    return if champs_to_remove.empty?
    champs.where(id: champs_to_remove).destroy_all
  end

  def remove_not_visible_rows!
    row_to_remove_ids = project_champs_public
      .filter { _1.repetition? && !_1.visible? }
      .flat_map(&:row_ids)

    return if row_to_remove_ids.empty?
    champs.where(row_id: row_to_remove_ids).destroy_all
  end

  def remove_titres_identite!
    champ_to_remove_ids = filled_champs.filter(&:titre_identite?).map(&:id)

    return if champ_to_remove_ids.empty?
    champs.where(id: champ_to_remove_ids).destroy_all
  end
end
