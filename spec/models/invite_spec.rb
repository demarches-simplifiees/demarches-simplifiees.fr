require 'spec_helper'

describe Invite do
  describe 'database columns' do
    it { is_expected.to have_db_column(:email) }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:dossier) }
    it { is_expected.to belong_to(:user) }
  end

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
  end
end
