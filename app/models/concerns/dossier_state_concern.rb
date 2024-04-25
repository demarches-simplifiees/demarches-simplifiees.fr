module DossierStateConcern
  extend ActiveSupport::Concern

  def after_passer_en_construction
    self.conservation_extension = 0.days
    self.depose_at = self.en_construction_at = self.traitements
      .passer_en_construction
      .processed_at

    save!

    RoutingEngine.compute(self)

    MailTemplatePresenterService.create_commentaire_for_state(self, Dossier.states.fetch(:en_construction))
    procedure.compute_dossiers_count

    index_search_terms_later
  end

  def after_commit_passer_en_construction
    NotificationMailer.send_en_construction_notification(self).deliver_later
    NotificationMailer.send_notification_for_tiers(self).deliver_later if self.for_tiers?
  end

  def after_passer_en_instruction(h)
    instructeur = h[:instructeur]
    instructeur.follow(self)

    self.en_construction_close_to_expiration_notice_sent_at = nil
    self.conservation_extension = 0.days
    self.en_instruction_at = self.traitements
      .passer_en_instruction(instructeur: instructeur)
      .processed_at
    save!

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
  end

  def after_passer_automatiquement_en_instruction
    self.en_construction_close_to_expiration_notice_sent_at = nil
    self.conservation_extension = 0.days
    self.en_instruction_at = traitements.passer_en_instruction.processed_at

    if procedure.declarative_en_instruction?
      self.declarative_triggered_at = en_instruction_at
    end

    save!

    MailTemplatePresenterService.create_commentaire_for_state(self, Dossier.states.fetch(:en_instruction))

    if procedure.sva_svr_enabled?
      # TODO: handle serialization errors when SIRET demandeur was not completed
      log_automatic_dossier_operation(:passer_en_instruction, self)
    else
      log_automatic_dossier_operation(:passer_en_instruction)
    end
  end

  def after_commit_passer_automatiquement_en_instruction
    NotificationMailer.send_en_instruction_notification(self).deliver_later
    NotificationMailer.send_notification_for_tiers(self).deliver_later if self.for_tiers?
  end

  def after_repasser_en_construction(h)
    instructeur = h[:instructeur]

    create_missing_traitemets

    self.en_construction_close_to_expiration_notice_sent_at = nil
    self.conservation_extension = 0.days
    self.en_construction_at = self.traitements
      .passer_en_construction(instructeur: instructeur)
      .processed_at

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
    remove_titres_identite!
  end

  def after_accepter_automatiquement
    self.processed_at = traitements.accepter_automatiquement.processed_at

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
    remove_titres_identite!
  end

  def after_refuser(h)
    instructeur = h[:instructeur]
    motivation = h[:motivation]
    justificatif = h[:justificatif]

    self.processed_at = self.traitements
      .refuser(motivation: motivation, instructeur: instructeur)
      .processed_at
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
    remove_titres_identite!
  end

  def after_refuser_automatiquement
    # Only SVR can refuse automatically
    I18n.with_locale(user.locale || I18n.default_locale) do
      self.motivation = I18n.t("shared.dossiers.motivation.refused_by_svr")
    end

    self.processed_at = traitements.refuser_automatiquement(motivation:).processed_at
    self.sva_svr_decision_triggered_at = self.processed_at

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
    remove_titres_identite!
  end

  def after_classer_sans_suite(h)
    instructeur = h[:instructeur]
    motivation = h[:motivation]
    justificatif = h[:justificatif]

    self.processed_at = self.traitements
      .classer_sans_suite(motivation: motivation, instructeur: instructeur)
      .processed_at
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
    remove_titres_identite!
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
end
