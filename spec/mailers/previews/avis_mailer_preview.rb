# Preview all emails at http://localhost:3000/rails/mailers/avis_mailer
class AvisMailerPreview < ActionMailer::Preview

  def you_are_invited_on_dossier
    AvisMailer.you_are_invited_on_dossier(Avis.last)
  end

end
