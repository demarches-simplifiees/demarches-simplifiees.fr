# frozen_string_literal: true

# Preview all emails at http://localhost:3000/rails/mailers/avis_mailer
class AvisMailerPreview < ActionMailer::Preview
  def avis_invitation
    procedure = Procedure.new(libelle: 'une belle procedure')
    dossier = Dossier.new(id: 1, procedure:)
    def dossier.visible_by_administration? = true
    claimant = Instructeur.new(user: User.new(email: 'claimant@ds.fr'))

    expert = Expert.new(user: User.new(email: '1@sa.com'))

    avis = Avis.new(
      id: 1,
      introduction: 'intro',
      dossier:,
      expert:,
      claimant:,
      procedure:
    )

    def avis.targeted_user_links
      stub = {}
      def stub.find_or_create_by(_h)
        TargetedUserLink.new(id: SecureRandom.uuid)
      end
      stub
    end

    AvisMailer.avis_invitation(avis, nil)
  end
end
