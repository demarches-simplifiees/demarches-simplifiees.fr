require 'rails_helper'

RSpec.describe DossierTransfer, type: :model do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:dossier) { create(:dossier, user: user) }

  describe 'initiate' do
    subject { DossierTransfer.initiate(other_user.email, [dossier]) }

    it 'should send transfer request' do
      expect(subject.email).to eq(other_user.email)
      expect(subject.dossiers).to eq([dossier])
      expect(dossier.transfer).to eq(subject)
      expect(dossier.user).to eq(user)
      expect(dossier.transfer_logs.count).to eq(0)
    end

    describe 'accept' do
      let(:transfer_log) { dossier.transfer_logs.first }

      before do
        DossierTransfer.accept(subject.id, other_user)
        dossier.reload
      end

      it 'should transfer dossier' do
        expect(DossierTransfer.count).to eq(0)
        expect(dossier.transfer).to be_nil
        expect(dossier.user).to eq(other_user)
        expect(dossier.transfer_logs.count).to eq(1)
        expect(transfer_log.dossier).to eq(dossier)
        expect(transfer_log.from).to eq(user.email)
        expect(transfer_log.to).to eq(other_user.email)
      end
    end

    describe 'with_dossiers' do
      before { subject }

      it { expect(DossierTransfer.with_dossiers.count).to eq(1) }

      context "when dossier discarded" do
        before { dossier.discard! }

        it { expect(DossierTransfer.with_dossiers.count).to eq(0) }
      end
    end
  end
end
