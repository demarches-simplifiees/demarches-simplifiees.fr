require 'spec_helper'

describe Invite do
  describe 'an email can be used for multiple dossier' do
    let(:email1) { 'plop@octo.com' }

    let!(:dossier1) { create(:dossier) }
    let!(:dossier2) { create(:dossier) }

    context 'when an email is invite on two dossier' do
      subject do
        create(:invite, email: email1, dossier: dossier1)
        create(:invite, email: email1, dossier: dossier2)
      end

      it { expect{ subject }.to change(Invite, :count).by(2) }
    end

    context 'when an email is invite twice on a dossier' do
      subject do
        create(:invite, email: email1, dossier: dossier1)
        create(:invite, email: email1, dossier: dossier1)
      end

      it { expect{ subject }.to raise_error ActiveRecord::RecordInvalid }
    end

    context "email validation" do
      let(:invite) { build(:invite, email: email, dossier: dossier1) }

      context 'when an email is invalid' do
        let(:email) { 'toto.fr' }

        it do
          expect(invite.save).to be false
          expect(invite.errors.full_messages).to eq(["Email n'est pas valide"])
        end

        context 'when an email is empty' do
          let(:email) { nil }

          it do
            expect(invite.save).to be false
            expect(invite.errors.full_messages).to eq(["Email est vide"])
          end
        end
      end

      context 'when an email is valid' do
        let(:email) { 'toto@toto.fr' }

        it do
          expect(invite.save).to be true
          expect(invite.errors.full_messages).to eq([])
        end
      end
    end
  end
end
