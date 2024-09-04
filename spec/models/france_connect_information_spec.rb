# frozen_string_literal: true

describe FranceConnectInformation, type: :model do
  describe 'validation' do
    context 'france_connect_particulier_id' do
      it { is_expected.not_to allow_value(nil).for(:france_connect_particulier_id) }
      it { is_expected.not_to allow_value('').for(:france_connect_particulier_id) }
      it { is_expected.to allow_value('mon super projet').for(:france_connect_particulier_id) }
    end
  end

  describe 'associate_user!' do
    context 'when there is no user with same email' do
      let(:email) { 'A@email.com' }
      let(:fci) { build(:france_connect_information) }

      subject { fci.associate_user!(email) }

      it { expect { subject }.to change(User, :count).by(1) }

      it do
        subject
        expect(fci.user.email).to eq('a@email.com')
        expect(fci.user.email_verified_at).to be_present
      end
    end
  end

  describe '#valid_for_merge?' do
    let(:fci) { create(:france_connect_information) }

    subject { fci.valid_for_merge? }

    context 'when the merge token is young enough' do
      before { fci.merge_token_created_at = 1.minute.ago }

      it { is_expected.to be(true) }

      context 'but the fci is already linked to an user' do
        before { fci.update(user: create(:user)) }

        it { is_expected.to be(false) }
      end
    end

    context 'when the merge token is too old' do
      before { fci.merge_token_created_at = (FranceConnectInformation::MERGE_VALIDITY + 1.minute).ago }

      it { is_expected.to be(false) }
    end
  end

  describe '#create_merge_token!' do
    let(:fci) { create(:france_connect_information) }

    it 'returns a merge_token and register it s creation date' do
      token = fci.create_merge_token!

      expect(fci.merge_token).to eq(token)
      expect(fci.merge_token_created_at).not_to be_nil
    end
  end
end
