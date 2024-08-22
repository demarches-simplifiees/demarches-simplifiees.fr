# frozen_string_literal: true

class ExpertMailer < ApplicationMailer
  helper MailerHelper
  layout 'mailers/layout'

  # TODO: replace with v2 after MEP
  def send_dossier_decision(avis_id)
    @avis = Avis.eager_load(:dossier).find(avis_id)
    @dossier = @avis.dossier
    email = @avis.expert.email
    @decision = decision_dossier(@dossier)
    subject = "Dossier n° #{@dossier.id} a été #{@decision} - #{@dossier.procedure.libelle}"

    mail(to: email, subject: subject)
  end

  def send_dossier_decision_v2(avis)
    @avis = avis
    @dossier = @avis.dossier
    email = @avis.expert.email
    @decision = decision_dossier(@dossier)
    subject = "Dossier n° #{@dossier.id} a été #{@decision} - #{@dossier.procedure.libelle}"

    mail(template_name: 'send_dossier_decision', to: email, subject: subject)
  end

  def self.critical_email?(action_name)
    false
  end
end

def decision_dossier(dossier)
  if dossier.accepte?
    'accepté'
  elsif dossier.sans_suite?
    'classé sans suite'
  elsif dossier.refuse?
    'refusé'
  end
end
