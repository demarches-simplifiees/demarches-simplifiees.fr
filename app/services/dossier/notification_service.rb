class Dossier::NotificationService < EventHandlerService
  def perform(event)
    return if event.metadata.fetch(:disable_notification, false)

    case event.event_type
    when 'DossierDepose'
      NotificationMailer.send_en_construction_notification(dossier).deliver_later
      dossier.groupe_instructeur.instructeurs.with_instant_email_dossier_notifications.find_each do |instructeur|
        DossierMailer.notify_new_dossier_depose_to_instructeur(dossier, instructeur.email).deliver_later
      end
    when 'DossierPasseEnInstruction'
      NotificationMailer.send_en_instruction_notification(dossier).deliver_later
    when 'DossierAccepte'
      NotificationMailer.send_accepte_notification(dossier).deliver_later
    when 'DossierRefuse'
      NotificationMailer.send_refuse_notification(dossier).deliver_later
    when 'DossierClasseSansSuite'
      NotificationMailer.send_sans_suite_notification(dossier).deliver_later
    when 'DossierRepasseEnInstruction'
      DossierMailer.notify_revert_to_instruction(dossier).deliver_later
    end
  end
end
