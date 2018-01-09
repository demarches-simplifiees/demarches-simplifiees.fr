module Mails
  class WithoutContinuationMail < ApplicationRecord
    include MailTemplateConcern

    belongs_to :procedure

    SLUG = "without_continuation"
    TEMPLATE_NAME = "mails/without_continuation_mail"
    DISPLAYED_NAME = 'Accusé de classement sans suite'
    DEFAULT_SUBJECT = 'Votre dossier TPS nº --numéro du dossier-- a été classé sans suite'
    IS_DOSSIER_TERMINE = true
  end
end
