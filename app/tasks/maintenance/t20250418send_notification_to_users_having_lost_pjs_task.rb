# frozen_string_literal: true

module Maintenance
  class T20250418sendNotificationToUsersHavingLostPjsTask < MaintenanceTasks::Task
    # Documentation: informe par email les usagers et instructeurs dont des PJ
    # ont été perdues suite à un bug introduit dans la release 2025-03-11-01
    # avec le storage OpenStack.

    no_collection

    include RunnableOnDeployConcern
    include StatementsHelpersConcern

    include ActionView::Helpers::NumberHelper
    include ActionView::Helpers::UrlHelper
    include ActionView::Helpers::SanitizeHelper
    include Rails.application.routes.url_helpers

    # Vous devez définir host par défaut pour les URL absolues
    default_url_options[:host] = APPLICATION_BASE_URL

    def process
      definitely_lost_keys = TaskLog.where("data->>'state' = ?", 'definitely lost')
        .where.not("data ? 'notified'")
        .pluck(Arel.sql("data->>'blob_key'"))
        .uniq

      blob_champ_pjs = ActiveStorage::Blob.where(key: definitely_lost_keys)
        .filter { it.attachments.first&.record_type == 'Champ' }
        .flat_map { |blob| blob.attachments.map { |att| [blob, att.record] } }
        .filter { |(_blob, champ)| champ&.public? }

      champ_pjs = blob_champ_pjs.map(&:second).uniq

      dossier_id_champs = champ_pjs.group_by { it.dossier_id }

      brouillon_or_en_construction = Dossier.visible_by_user.where(id: dossier_id_champs.keys, state: %w[brouillon en_construction])

      brouillon_or_en_construction.group_by { it.user.email }.each do |to, dossiers|
        dossiers_and_champs = dossiers.map { |dossier| [dossier, dossier_id_champs[dossier.id]] }
        send_mail(to:, body: user_body_email(dossiers_and_champs))

        blobs = dossiers.map(&:id).map do |dossier_id|
          dossier_id_champs[dossier_id]
            .map { |c| blob_champ_pjs.filter { |_, champ| champ == c }.map(&:first) }
        end.flatten.uniq

        blobs.each do |blob|
          TaskLog.where("data->>'blob_key' = ?", blob.key)
            .update_all(%(data = jsonb_set(data, '{notified}', '"user"')))
        end
      end

      en_instruction = Dossier.visible_by_administration.en_instruction.where(id: dossier_id_champs.keys)

      # On envoie un mail à chaque premier instructeur qui suit le dossier (?)
      en_instruction.group_by { it.followers_instructeurs.first&.email }.each do |to, dossiers|
        next if to.nil?

        dossiers_and_champs = dossiers.map { |dossier| [dossier, dossier_id_champs[dossier.id]] }
        send_mail(to:, body: instructeur_body_email(dossiers_and_champs))

        blobs = dossiers.map(&:id).map do |dossier_id|
          dossier_id_champs[dossier_id]
            .map { |c| blob_champ_pjs.filter { |_, champ| champ == c }.map(&:first) }
        end.flatten.uniq

        blobs.each do |blob|
          TaskLog.where("data->>'blob_key' = ?", blob.key)
            .update_all(%(data = jsonb_set(data, '{notified}', '"instructeur"')))
        end
      end
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

    def instructeur_body_email(dossiers_and_champs)
      <<~TEXT
        Bonjour,<br><br>

        En raison d'une erreur technique, les pièces jointes des dossiers suivants ne sont plus disponibles :

        #{to_html_list(list_of_missing_pjs_and_dossier(dossiers_and_champs, link_for: :instructeur))}

        Si ces pièces sont toujours nécessaires au traitement du dossier, pourriez-vous recontacter les usagers par la messagerie pour leur demander de les retransmettre ?<br><br>

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
