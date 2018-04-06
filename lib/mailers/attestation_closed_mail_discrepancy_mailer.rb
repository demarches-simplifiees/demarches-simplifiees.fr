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
        procedure_ids = "votre procédure nº #{procedures.first.id}"
      else
        procedure_ids = 'vos procédures nº ' + procedures.map{ |p| p.id }.join(', ')
      end
      "demarches-simplifiees.fr – mise à jour nécessaire de l’accusé d’acceptation de #{procedure_ids}"
    end

    def body(procedures)
      <<~HEREDOC
        Bonjour,

        Pour des raisons de confidentialité, le mode de transmission des attestations aux usagers évolue.

        À compter du 30 avril, les mails d’accusé d’acceptation émis par demarches-simplifiees.fr ne
        comporteront plus d’attestation en pièce jointe comme c’est le cas aujourd’hui.

        À la place, le mail contiendra un lien permettant à l’usager de télécharger son
        attestation dirctement dans son espace sécurisé sur demarches-simplifiees.fr.

        Ce lien de téléchargement est généré par la balise --lien attestation--.

        #{detail_procedures(procedures)}

        Pour toute question vous pouvez nous joindre par téléphone au 01 76 42 02 87
        ou sur l’adresse email contact@demarches-simplifiees.fr.
        -- \nL’équipe demarches-simplifiees.fr
      HEREDOC
    end

    def detail_procedures(procedures)
      if procedures.count == 1
        p = procedures.first

        <<~HEREDOC.chomp
          Vous êtes administrateur de la procédure suivante :
          #{p.libelle} (nº #{p.id})

          Cette procédure donne lieu à l’émission d’une attestation, et son accusé
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
          Vous êtes administrateur sur plusieurs procédures qui donnent lieu à l’émission
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
