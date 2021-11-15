class NotifyNewAnswerWithDelayJob < ApplicationJob
  queue_as :exports # for now?

  discard_on ActiveRecord::RecordNotFound

  def perform(dossier, body, commentaire)
    return if commentaire.soft_deleted?
    DossierMailer.notify_new_answer(dossier, body)
  end
end
