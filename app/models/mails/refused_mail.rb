# frozen_string_literal: true

# == Schema Information
#
# Table name: refused_mails
#
#  id           :integer          not null, primary key
#  body         :text
#  subject      :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  procedure_id :integer
#
module Mails
  # refuse
  class RefusedMail < ApplicationRecord
    include MailTemplateConcern

    belongs_to :procedure, optional: false

    validates :subject, tags: true
    validates :body, tags: true

    SLUG = "refused_mail"
    DEFAULT_TEMPLATE_NAME = "notification_mailer/default_templates/refused_mail"
    DISPLAYED_NAME = 'Accusé de rejet du dossier'
    DEFAULT_SUBJECT = 'Votre dossier nº --numéro du dossier-- a été refusé (--libellé démarche--)'
    DOSSIER_STATE = Dossier.states.fetch(:refuse)

    def actions_for_dossier(dossier)
      [MailTemplateConcern::Actions::REPLY, MailTemplateConcern::Actions::SHOW]
    end
  end
end
