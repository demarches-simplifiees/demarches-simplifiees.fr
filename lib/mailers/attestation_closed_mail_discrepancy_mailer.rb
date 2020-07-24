module Mailers
  class AttestationClosedMailDiscrepancyMailer < ApplicationMailer
    include Rails.application.routes.url_helpers

    def missing_attestation_tag_email(admin, procedures)
      procedures = procedures.sort_by(&:id)
      mail(to: admin.email, subject: subject(procedures), body: body(procedures))
    end

    private

    def subject(procedures)
      if procedures.count == 1
        procedure_ids = "votre démarche nº #{procedures.first.id}"
      else
        procedure_ids = 'vos démarches nº ' + procedures.map(&:id).join(', ')
      end
      "#{APPLICATION_NAME} – mise à jour nécessaire de l’accusé d’acceptation de #{procedure_ids}"
    end

    def body(procedures)
      <<~HEREDOC
        Bonjour,

        Pour des raisons de confidentialité, le mode de transmission des attestations aux usagers évolue.

        À compter du 30 avril, les mails d’accusé d’acceptation émis par #{APPLICATION_NAME} ne
        comporteront plus d’attestation en pièce jointe comme c’est le cas aujourd’hui.

        À la place, le mail contiendra un lien permettant à l’usager de télécharger son
        attestation dirctement dans son espace sécurisé sur #{APPLICATION_NAME}.

        Ce lien de téléchargement est généré par la balise --lien attestation--.

        #{detail_procedures(procedures)}

        Pour toute question vous pouvez nous joindre par téléphone au #{CONTACT_PHONE}
        ou sur l’adresse email #{CONTACT_EMAIL}.
        -- \nL’équipe #{APPLICATION_NAME}
      HEREDOC
    end

    def detail_procedures(procedures)
      if procedures.count == 1
        p = procedures.first

        <<~HEREDOC.chomp
          Vous êtes administrateur de la démarche suivante :
          #{p.libelle} (nº #{p.id})

          Cette démarche donne lieu à l’émission d’une attestation, et son accusé
          d’acceptation a été personnalisé. Pour respecter la rédaction de votre accusé
          d’acceptation, nous ne prendrons pas l’initiative d’y ajouter la balise --lien attestation--.

          Afin que vos usagers puissent continuer à accéder facilement à leurs attestations
          dans leurs démarches futures, nous vous invitons à ajouter à votre convenance la
          balise --lien attestation-- dans votre accusé d’acceptation. Vous pouvez le faire en
          cliquant sur le lien suivant :

          #{edit_admin_procedure_mail_template_url(p, Mails::ClosedMail::SLUG)}
        HEREDOC
      else
        liste_procedures = procedures.map { |p| "- #{p.libelle} (nº #{p.id}) – #{edit_admin_procedure_mail_template_url(p, Mails::ClosedMail::SLUG)}" }.join("\n")

        <<~HEREDOC.chomp
          Vous êtes administrateur sur plusieurs démarches qui donnent lieu à l’émission
          d’une attestation, et dont l’accusé d’acceptation a été personnalisé. Pour respecter
          la rédaction de vos accusés d’acceptation, nous ne prendrons pas l’initiative d’y
          ajouter de balise --lien attestation--.

          Afin que vos usagers puissent continuer à accéder facilement à leurs attestations
          dans leurs démarches futures, nous vous invitons à ajouter à votre convenance la
          balise --lien attestation-- dans vos accusés d’acceptation.

          Vous trouverez ci-après la liste des démarches concernées, ainsi que les liens vous
          permettant d’éditer les accusés d’acceptation correspondants.

          #{liste_procedures}
        HEREDOC
      end
    end
  end
end
