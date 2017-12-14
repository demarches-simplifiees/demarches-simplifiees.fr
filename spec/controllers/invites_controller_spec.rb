require 'spec_helper'

describe InvitesController, type: :controller do
  let(:dossier) { create(:dossier, :en_construction) }
  let(:email) { 'plop@octo.com' }

  describe '#POST create' do
    let(:invite) { Invite.last }

    before do
      sign_in signed_in_profile
    end

    subject { post :create, params: {dossier_id: dossier.id, email: email} }

    context "when gestionnaire is signed_in" do
      let(:signed_in_profile) { create(:gestionnaire) }

      shared_examples_for "he can not create invitation" do
        it { expect { subject }.to raise_error(ActiveRecord::RecordNotFound) }
        it { expect { subject rescue nil }.to change(InviteGestionnaire, :count).by(0) }
      end

      context 'when gestionnaire has no access to dossier' do
        it_behaves_like "he can not create invitation"
      end

      context 'when gestionnaire is invited for avis on dossier' do
        before { Avis.create(gestionnaire: signed_in_profile, claimant: create(:gestionnaire), dossier: dossier) }

        it_behaves_like "he can not create invitation"
      end

      context 'when gestionnaire has access to dossier' do
        before do
          signed_in_profile.procedures << dossier.procedure
        end

        it { expect { subject }.to change(InviteGestionnaire, :count).by(1) }

        context 'when is a user who is loged' do
          before do
            sign_in create(:user)
          end

          it { expect { subject }.to change(InviteGestionnaire, :count).by(1) }
        end

        context 'when email is assign to an user' do
          let! (:user) { create(:user, email: email) }

          before do
            subject
          end

          describe 'Invite information' do
            let(:email) { 'PLIP@octo.com' }
            let(:invite) { Invite.last }

            it 'email is on lower case' do
              expect(invite.email).to eq 'plip@octo.com'
            end
          end

          it { expect(invite.user).to eq user }
          it { expect(flash[:notice]).to be_present }
        end

        context 'when email is not assign to an user' do
          before do
            subject
          end

          it { expect(invite.user).to be_nil }
          it { expect(flash[:notice]).to be_present }
        end

        describe 'not an email' do
          context 'when email is not valid' do
            let(:email) { 'plip.com' }

            before do
              subject
            end

            it { expect { subject }.not_to change(Invite, :count) }
            it { expect(flash[:alert]).to be_present }
          end

          context 'when email is already used' do
            let!(:invite) { create(:invite, dossier: dossier) }

            before do
              subject
            end

            it { expect { subject }.not_to change(Invite, :count) }
            it { expect(flash[:alert]).to be_present }
          end
        end

        describe 'send invitation email' do
          context 'when user does not exist' do
            it 'send email' do
              expect(InviteMailer).to receive(:invite_guest).and_return(InviteMailer)
              expect(InviteMailer).to receive(:deliver_now!)

              subject
            end
          end

          context 'when user exist' do
            before do
              create :user, email: email
            end

            it 'send email' do
              expect(InviteMailer).to receive(:invite_user).and_return(InviteMailer)
              expect(InviteMailer).to receive(:deliver_now!)

              subject
            end
          end
        end
      end
    end

    context "when user is signed_in" do
      let(:signed_in_profile) { create(:user) }

      shared_examples_for "he can not create a invite" do
        it { expect { subject }.to raise_error(ActiveRecord::RecordNotFound) }
        it { expect { subject rescue nil }.to change(InviteUser, :count).by(0) }
      end

      context 'when user has no access to dossier' do
        it_behaves_like "he can not create a invite"
      end

      context 'when user is invited on dossier' do
        before { Invite.create(user: signed_in_profile, email: signed_in_profile.email, dossier: dossier) }

        it_behaves_like "he can not create a invite"
      end

      context 'when user has access to dossier' do
        before do
          dossier.update_attributes(user: signed_in_profile)
        end

        it { expect { subject }.to change(InviteUser, :count).by(1) }
      end
    end
  end
end
