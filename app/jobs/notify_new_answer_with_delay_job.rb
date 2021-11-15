class NotifyNewAnswerWithDelayJob < ApplicationJob
  queue_as :mailers # use default queue for email, same priority

  discard_on ActiveRecord::RecordNotFound

  def perform(dossier, body, commentaire)
    return if commentaire.soft_deleted?
    DossierMailer.notify_new_answer(dossier, body).deliver_now
  end
end
