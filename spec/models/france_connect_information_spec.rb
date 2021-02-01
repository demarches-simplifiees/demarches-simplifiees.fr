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
      let(:fci) { create(:france_connect_information) }
      let(:subject) { fci.associate_user! }

      it { expect { subject }.to change(User, :count).by(1) }
      it do
        subject
        expect(fci.user.email).to eq(fci.email_france_connect)
      end
    end

    context 'when a user with same email (but who is not an instructeur) exist' do
      let(:user) { create(:user) }
      let(:fci) { build(:france_connect_information, email_france_connect: user.email) }
      let(:subject) { fci.associate_user! }

      before { subject }

      it { expect(fci.user).to eq(user) }
    end
  end
end
