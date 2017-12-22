module Mails
  class WithoutContinuationMail < ApplicationRecord
    include MailTemplateConcern

    belongs_to :procedure

    SLUG = "without_continuation"
    TEMPLATE_NAME = "mails/without_continuation_mail"
    DISPLAYED_NAME = 'Accusé de classement sans suite'
    DEFAULT_OBJECT = 'Votre dossier TPS nº --numero_dossier-- a été classé sans suite'
    IS_FOR_CLOSED_DOSSIER = true
  end
end
