# == Schema Information
#
# Table name: initiated_mails
#
#  id           :integer          not null, primary key
#  body         :text
#  subject      :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  procedure_id :integer
#
module Mails
  class RepasserEnConstructionMail < ApplicationRecord
    include MailTemplateConcern

    belongs_to :procedure, optional: false

    SLUG = "initiated_mail"
    DEFAULT_TEMPLATE_NAME = "notification_mailer/default_templates/revert_to_construction_mail"
    DISPLAYED_NAME = I18n.t('activerecord.models.mail.revert_to_construction.revert_to_construction')
    DEFAULT_SUBJECT = I18n.t('activerecord.models.mail.revert_to_construction.default_subject', dossier_number: '--numéro du dossier--', procedure_libelle: '--libellé démarche--')
    DOSSIER_STATE = Dossier.states.fetch(:en_construction)

    def attachment_for_dossier(dossier)
      {
        filename: I18n.t('users.dossiers.show.papertrail.filename'),
        content: deposit_receipt_for_dossier(dossier)
      }
    end

    private

    def deposit_receipt_for_dossier(dossier)
      ApplicationController.render(
        template: 'users/dossiers/papertrail',
        formats: [:pdf],
        assigns: { dossier: dossier }
      )
    end
  end
end
