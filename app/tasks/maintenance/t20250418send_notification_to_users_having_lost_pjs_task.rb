# frozen_string_literal: true

module Maintenance
  class T20250418sendNotificationToUsersHavingLostPjsTask < MaintenanceTasks::Task
    # Documentation: informe par email les usagers et instructeurs dont des PJ
    # ont été perdues suite à un bug introduit dans la release 2025-03-11-01
    # avec le storage OpenStack.

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    include ActionView::Helpers::NumberHelper
    include ActionView::Helpers::UrlHelper
    include ActionView::Helpers::SanitizeHelper
    include Rails.application.routes.url_helpers

    # Vous devez définir host par défaut pour les URL absolues
    default_url_options[:host] = APPLICATION_BASE_URL

    def collection
      TaskLog.where("data->>'state' = ?", 'definitely lost')
        .where("data ? 'email'")
        .pluck(Arel.sql("data->>'email'"))
        .uniq
        .sort
    end

    def process(email)
      task_logs = TaskLog.where("data->>'state' = ?", 'definitely lost')
        .where("data->>'email' = ?", email)
        .where.not("data ? 'notified'")

      return if task_logs.empty?

      blob_keys = task_logs.map { it.data["blob_key"] }

      blob_champ_pjs = ActiveStorage::Blob.includes(:attachments).where(key: blob_keys)
        .filter { it.attachments.first&.record_type == 'Champ' && it.attachments.first&.record&.public? }
        .flat_map { |blob| blob.attachments.map { |att| [blob, att.record] } }

      champ_pjs = blob_champ_pjs.map(&:second).uniq.sort_by(&:id)

      dossier_id_champs = champ_pjs.group_by { it.dossier_id }

      brouillon_or_en_construction = Dossier.visible_by_user.includes(:user).where(id: dossier_id_champs.keys, state: %w[brouillon en_construction])
      brouillon_or_en_construction.group_by { it.user.email }.each do |to, dossiers|
        dossiers_and_champs = dossiers.map { |dossier| [dossier, dossier_id_champs[dossier.id]] }
        send_mail(to:, body: user_body_email(dossiers_and_champs))
      end

      task_logs.update_all(%(data = jsonb_set(data, '{notified}', '"user"')))
    end

    def send_mail(to:, body:)
      subject = "[#{APPLICATION_NAME}] Action requise : pièces jointes manquantes"
      title = "Pièces jointes manquantes"
      BlankMailer.send_template(to:, subject:, title:, body:).deliver_later
    end

    def user_body_email(dossiers_and_champs)
      <<~TEXT
        Bonjour,<br><br>

        En raison d'une erreur technique, les pièces jointes suivantes ne sont plus disponibles :

        #{to_html_list(list_of_missing_pjs_and_dossier(dossiers_and_champs, link_for: :user))}

        Nous vous invitons à joindre à nouveau ce(s) fichier(s)
        même si un aperçu de la pièce jointe apparaît encore dans votre dossier.<br>

        Nous restons à votre disposition pour toute question sur #{CONTACT_EMAIL} .<br><br>

        Nous vous prions de nous excuser pour la gêne occasionnée par cet incident.
      TEXT
    end

    def list_of_missing_pjs_and_dossier(dossiers_and_champs, link_for:)
      dossiers_and_champs.map do |dossier, champs|
        url = if link_for == :user
          Rails.application.routes.url_helpers.dossier_url(dossier)
        else
          Rails.application.routes.url_helpers.instructeur_dossier_url(dossier.procedure.id, dossier)
        end

        dossier_link = tag.a("dossier Nº #{number_with_delimiter(dossier.id)}", href: url)
        "#{champs.map(&:libelle).join(', ')} du #{dossier_link} sur la démarche #{dossier.procedure.libelle}"
      end
    end

    def to_html_list(messages)
      messages
        .map { |message| tag.li(sanitize(message, scrubber: Sanitizers::MailScrubber.new)) }
        .then { |lis| tag.ul(lis.reduce(&:+)) }
    end
  end
end
