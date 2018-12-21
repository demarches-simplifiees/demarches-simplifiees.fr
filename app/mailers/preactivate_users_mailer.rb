class PreactivateUsersMailer < ApplicationMailer
  layout 'mailers/layout'

  def reinvite(model, model_name)
    subject = "Votre compte #{model_name} est activé sur #{SITE_NAME}"
    signature_separator = "-- "
    body = <<~END_OF_MAIL
      Bonjour,

      les activations de compte #{model_name} sur #{SITE_NAME}
      ont connu depuis deux semaines un fonctionnement erratique, et nous
      pensons que votre inscription sur #{SITE_NAME} a pu s’en
      trouver affectée.

      Nous avons maintenant rétabli un fonctionnement normal de l’activation
      des comptes. Vous pouvez désormais vous connecter sans encombres à votre
      compte #{model_name} sur #{SITE_NAME}.
      Si toutefois des difficultés devaient persister, n’hésitez pas à nous
      en faire part.

      Nous vous présentons nos excuses pour la gène occasionnée.

      Cordialement
      #{signature_separator}
      L’équipe demarches-simplifees.fr
    END_OF_MAIL

    mail(to: model.email,
      subject: subject,
      reply_to: CONTACT_EMAIL,
      body: body)
  end
end
