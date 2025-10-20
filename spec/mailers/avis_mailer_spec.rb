# frozen_string_literal: true

RSpec.describe AvisMailer, type: :mailer do
  describe '.avis_invitation' do
    let(:claimant) { create(:instructeur) }
    let(:expert) { create(:expert) }
    let(:dossier) { create(:dossier, :en_construction) }
    let(:experts_procedure) { create(:experts_procedure, expert: expert, procedure: dossier.procedure) }
    let(:avis) { create(:avis, dossier: dossier, claimant: claimant, experts_procedure: experts_procedure, introduction: 'intro') }

    subject { described_class.avis_invitation(avis.reload) }

    it do
      expect(subject.subject).to eq("Donnez votre avis sur le dossier n° #{avis.dossier.id} (#{avis.dossier.procedure.libelle})")
      expect(subject.body).to have_text("Vous avez été invité par\r\n#{avis.claimant.email}\r\nà donner votre avis sur le dossier n° #{avis.dossier.id} de la démarche :\r\n#{avis.dossier.procedure.libelle}")
      expect(subject.body).to include(avis.introduction)
      expect(subject.body).to include(targeted_user_link_url(TargetedUserLink.where(target_model: avis).first))
    end

    it do
      expect { subject.body }.to change { TargetedUserLink.where(target_model: avis).count }.from(0).to(1)
    end

    context 'when the dossier has been deleted before the avis was sent' do
      before { dossier.update(hidden_by_user_at: 1.hour.ago) }

      it 'doesn’t send the email' do
       expect(subject.body).to be_blank
     end
    end
  end

  describe '.avis_invitation_and_confirm_email' do
    let(:claimant) { create(:instructeur) }
    let(:dossier) { create(:dossier, :en_construction) }
    let(:experts_procedure) { create(:experts_procedure, expert: expert, procedure: dossier.procedure) }
    let(:avis) { create(:avis, dossier: dossier, claimant: claimant, experts_procedure: experts_procedure, introduction: 'intro') }
    let(:expert) { create(:expert, user:) }

    subject { described_class.avis_invitation_and_confirm_email(user, user.confirmation_token, avis.reload) }

    context 'when expert is active and verified' do
      let(:user) { create(:user, :active, :with_email_verified, confirmation_token: "token") }
      it do
        expect(subject.subject).to eq("Donnez votre avis sur le dossier n° #{avis.dossier.id} (#{avis.dossier.procedure.libelle})")
        expect(subject.body).to have_text("Vous avez été invité par\r\n#{avis.claimant.email}\r\nà donner votre avis sur le dossier n° #{avis.dossier.id} de la démarche :\r\n#{avis.dossier.procedure.libelle}")
        expect(subject.body).to have_text("Donnez votre avis")
        expect(subject.body).to include(avis.introduction)
        expect(subject.body).to include(targeted_user_link_url(TargetedUserLink.where(target_model: avis).first, confirmation_token: user.confirmation_token))
      end

      it do
        expect { subject.body }.to change { TargetedUserLink.where(target_model: avis).count }.from(0).to(1)
      end

      context 'when the dossier has been deleted before the avis was sent' do
        before { dossier.update(hidden_by_user_at: 1.hour.ago) }

        it 'doesn’t send the email' do
          expect(subject.body).to be_blank
        end
      end
    end

    context 'when expert is active and not verified' do
      let(:user) { create(:user, :active, email_verified_at: nil, confirmation_token: "token") }
      it do
        expect(subject.body).to include(targeted_user_link_url(TargetedUserLink.where(target_model: avis).first, confirmation_token: user.confirmation_token))
      end
      it do
        expect { subject.body }.to change { TargetedUserLink.where(target_model: avis).count }.from(0).to(1)
        expect(subject.body).to have_text("Confirmez votre adresse email pour donner votre avis")
      end
    end
    context 'when expert is inactive' do
      let(:user) { create(:user, :inactive, confirmation_token: 'token') }
      it do
        expect(subject.body).to include(targeted_user_link_url(TargetedUserLink.where(target_model: avis).first, confirmation_token: user.confirmation_token))
        expect(subject.body).to have_text("Inscrivez-vous pour donner votre avis")
      end

      it do
        expect { subject.body }.to change { TargetedUserLink.where(target_model: avis).count }.from(0).to(1)
      end
    end
  end
end
