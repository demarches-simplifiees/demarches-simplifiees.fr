# == Schema Information
#
# Table name: nouveau_brouillon_mails
#
#  id           :integer          not null, primary key
#  body         :text
#  subject      :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  procedure_id :integer
#
module Mails
  class NouveauBrouillonMail < ApplicationRecord
    include MailTemplateConcern

    belongs_to :procedure, optional: false

    SLUG = "nouveau_brouillon"
    DEFAULT_TEMPLATE_NAME = "notification_mailer/default_templates/nouveau_brouillon"
    DISPLAYED_NAME = I18n.t('activerecord.models.mail.nouveau_brouillon_mail.nouveau_brouillon')
    DEFAULT_SUBJECT = I18n.t('activerecord.models.mail.nouveau_brouillon_mail.default_subject', dossier_number: '--numéro du dossier--', procedure_libelle: '--libellé démarche--')
    DOSSIER_STATE = Dossier.states.fetch(:brouillon)

  end
end
