class NotificationMailerPreview < ActionMailer::Preview
  def send_en_construction_notification
    NotificationMailer.send_en_construction_notification(dossier_with_image)
  end

  def send_en_instruction_notification
    NotificationMailer.send_en_instruction_notification(dossier)
  end

  def send_accepte_notification
    NotificationMailer.send_accepte_notification(dossier)
  end

  def send_refuse_notification
    NotificationMailer.send_refuse_notification(dossier_with_motivation)
  end

  def send_sans_suite_notification
    NotificationMailer.send_sans_suite_notification(dossier)
  end

  private

  def dossier
    Dossier.last
  end

  def dossier_with_image
    procedure = Procedure.where(id: Mails::InitiatedMail.where("body like ?", "%<img%").pluck(:procedure_id).uniq).order("RANDOM()").first
    procedure.dossiers.last
  end

  def dossier_with_motivation
    Dossier.last.tap { |d| d.assign_attributes(motivation: 'Le montant demandé dépasse le plafond autorisé') }
  end
end
