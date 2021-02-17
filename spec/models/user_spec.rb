describe User, type: :model do
  describe '#after_confirmation' do
    let(:email) { 'mail@beta.gouv.fr' }
    let!(:invite) { create(:invite, email: email) }
    let!(:invite2) { create(:invite, email: email) }
    let(:user) do
      create(:user,
        email: email,
        password: TEST_PASSWORD,
        confirmation_token: '123',
        confirmed_at: nil)
    end

    it 'when confirming a user, it links the pending invitations to this user' do
      expect(user.invites.size).to eq(0)
      user.confirm
      expect(user.reload.invites.size).to eq(2)
    end
  end

  describe '#owns?' do
    let(:owner) { create(:user) }
    let(:dossier) { create(:dossier, user: owner) }
    let(:invite_user) { create(:user) }
    let(:invite_instructeur) { create(:user) }

    subject { user.owns?(dossier) }

    context 'when user is owner' do
      let(:user) { owner }

      it { is_expected.to be_truthy }
    end

    context 'when user was invited by user' do
      before do
        create(:invite, dossier: dossier, user: invite_user)
      end

      let(:user) { invite_user }

      it { is_expected.to be_falsy }
    end

    context 'when user is quidam' do
      let(:user) { create(:user) }

      it { is_expected.to be_falsey }
    end
  end

  describe '#invite?' do
    let(:dossier) { create :dossier }
    let(:user) { dossier.user }

    subject { user.invite? dossier.id }

    context 'when user is invite at the dossier' do
      before do
        create :invite, dossier_id: dossier.id, user: user
      end

      it { is_expected.to be_truthy }
    end

    context 'when user is not invite at the dossier' do
      it { is_expected.to be_falsey }
    end
  end

  describe '#owns_or_invite?' do
    let(:owner) { create(:user) }
    let(:dossier) { create(:dossier, user: owner) }
    let(:invite_user) { create(:user) }
    let(:invite_instructeur) { create(:user) }

    subject { user.owns_or_invite?(dossier) }

    context 'when user is owner' do
      let(:user) { owner }

      it { is_expected.to be_truthy }
    end

    context 'when user was invited by user' do
      before do
        create(:invite, dossier: dossier, user: invite_user)
      end

      let(:user) { invite_user }

      it { is_expected.to be_truthy }
    end

    context 'when user is quidam' do
      let(:user) { create(:user) }

      it { is_expected.to be_falsey }
    end
  end

  describe '.create_or_promote_to_instructeur' do
    let(:email) { 'inst1@gmail.com' }
    let(:password) { 'un super password !' }
    let(:admins) { [] }

    subject { User.create_or_promote_to_instructeur(email, password, administrateurs: admins) }

    context 'without an existing user' do
      it do
        user = subject
        expect(user.valid_password?(password)).to be true
        expect(user.confirmed_at).to be_present
        expect(user.instructeur).to be_present
      end

      context 'with an administrateur' do
        let(:admins) { [create(:administrateur)] }

        it do
          user = subject
          expect(user.instructeur.administrateurs).to eq(admins)
        end
      end
    end

    context 'with an existing user' do
      before { create(:user, email: email, password: TEST_PASSWORD) }

      it 'keeps the previous password' do
        user = subject
        expect(user.valid_password?(TEST_PASSWORD)).to be true
        expect(user.instructeur).to be_present
      end

      context 'with an existing instructeur' do
        let(:old_admins) { [create(:administrateur)] }
        let(:admins) { [create(:administrateur)] }
        let!(:instructeur) { create(:instructeur, email: 'i@mail.com', administrateurs: old_admins) }

        before do
          User
            .find_by(email: email)
            .update!(instructeur: instructeur)
        end

        it 'keeps the existing instructeurs and adds administrateur' do
          user = subject
          expect(user.instructeur).to eq(instructeur)
          expect(user.instructeur.administrateurs).to match_array(old_admins + admins)
        end
      end
    end

    context 'with an invalid email' do
      let(:email) { 'invalid' }

      it 'does not build an instructeur' do
        user = subject
        expect(user.valid?).to be false
        expect(user.instructeur).to be_nil
      end
    end
  end

  describe '.create_or_promote_to_expert' do
    let(:email) { 'exp1@gmail.com' }
    let(:password) { 'un super expert !' }

    subject { User.create_or_promote_to_expert(email, password) }

    context 'with an invalid email' do
      let(:email) { 'invalid' }

      it 'does not build an expert' do
        user = subject
        expect(user.valid?).to be false
        expect(user.expert).to be_nil
      end
    end

    context 'without an existing user' do
      it do
        user = subject
        expect(user.valid_password?(password)).to be true
        expect(user.confirmed_at).to be_present
        expect(user.expert).to be_present
      end
    end

    context 'with an existing user' do
      before { create(:user, email: email, password: 'my-s3cure-p4ssword') }

      it 'keeps the previous password' do
        user = subject
        expect(user.valid_password?('my-s3cure-p4ssword')).to be true
        expect(user.expert).to be_present
      end

      context 'with an existing expert' do
        let!(:expert) { Expert.create }

        before do
          User
            .find_by(email: email)
            .update!(expert: expert)
        end

        it 'keeps the existing experts' do
          user = subject
          expect(user.expert).to eq(expert)
        end
      end
    end
  end

  describe 'invite_administrateur!' do
    let(:super_admin) { create(:super_admin) }
    let(:administrateur) { create(:administrateur) }
    let(:user) { administrateur.user }

    let(:mailer_double) { double('mailer', deliver_later: true) }

    before { allow(AdministrationMailer).to receive(:invite_admin).and_return(mailer_double) }

    subject { user.invite_administrateur!(super_admin.id) }

    context 'when the user is inactif' do
      before { subject }

      it { expect(AdministrationMailer).to have_received(:invite_admin).with(user, kind_of(String), super_admin.id) }
    end

    context 'when the user is actif' do
      before do
        user.update(last_sign_in_at: Time.zone.now)
        subject
      end

      it 'receives an invitation to update its password' do
        expect(AdministrationMailer).to have_received(:invite_admin).with(user, kind_of(String), super_admin.id)
      end
    end
  end

  describe '#active?' do
    let!(:user) { create(:user) }

    subject { user.active? }

    context 'when the user has never signed in' do
      before { user.update(last_sign_in_at: nil) }

      it { is_expected.to be false }
    end

    context 'when the user has already signed in' do
      before { user.update(last_sign_in_at: Time.zone.now) }

      it { is_expected.to be true }
    end
  end

  describe '#can_be_deleted?' do
    let(:user) { create(:user) }

    subject { user.can_be_deleted? }

    context 'when the user has a dossier in instruction' do
      let!(:dossier) { create(:dossier, :en_instruction, user: user) }

      it { is_expected.to be false }
    end

    context 'when the user has no dossier in instruction' do
      it { is_expected.to be true }
    end

    context 'when the user is an administrateur' do
      it 'cannot be deleted' do
        administrateur = create(:administrateur)
        user = administrateur.user

        expect(user.can_be_deleted?).to be_falsy
      end
    end

    context 'when the user is an instructeur' do
      it 'cannot be deleted' do
        instructeur = create(:instructeur)
        user = instructeur.user

        expect(user.can_be_deleted?).to be_falsy
      end
    end
  end

  describe '#delete_and_keep_track_dossiers' do
    let(:super_admin) { create(:super_admin) }
    let(:user) { create(:user) }

    context 'with a dossier in instruction' do
      let!(:dossier_en_instruction) { create(:dossier, :en_instruction, user: user) }
      it 'raises' do
        expect { user.delete_and_keep_track_dossiers(super_admin) }.to raise_error(RuntimeError)
      end
    end

    context 'without a dossier in instruction' do
      let!(:dossier_en_construction) { create(:dossier, :en_construction, user: user) }
      let!(:dossier_brouillon) { create(:dossier, user: user) }

      context 'without a discarded dossier' do
        it "keep track of dossiers and delete user" do
          user.delete_and_keep_track_dossiers(super_admin)

          expect(DeletedDossier.find_by(dossier_id: dossier_en_construction)).to be_present
          expect(DeletedDossier.find_by(dossier_id: dossier_brouillon)).to be_nil
          expect(User.find_by(id: user.id)).to be_nil
        end
      end

      context 'with a discarded dossier' do
        let!(:dossier_cache) do
          create(:dossier, :en_construction, user: user)
        end
        let!(:dossier_from_another_user) do
          create(:dossier, :en_construction, user: create(:user))
        end

        it "keep track of dossiers and delete user" do
          dossier_cache.discard_and_keep_track!(super_admin, :user_request)
          user.delete_and_keep_track_dossiers(super_admin)

          expect(DeletedDossier.find_by(dossier_id: dossier_en_construction)).to be_present
          expect(DeletedDossier.find_by(dossier_id: dossier_brouillon)).to be_nil
          expect(User.find_by(id: user.id)).to be_nil
        end

        it "doesn't destroy dossiers of another user" do
          dossier_cache.discard_and_keep_track!(super_admin, :user_request)
          user.delete_and_keep_track_dossiers(super_admin)

          expect(Dossier.find_by(id: dossier_from_another_user.id)).to be_present
        end
      end
    end
  end

  describe '#password_complexity' do
    # This password list is sorted by password complexity, according to zxcvbn (used for complexity evaluation)
    # 0 - too guessable: risky password. (guesses < 10^3)
    # 1 - very guessable: protection from throttled online attacks. (guesses < 10^6)
    # 2 - somewhat guessable: protection from unthrottled online attacks. (guesses < 10^8)
    # 3 - safely unguessable: moderate protection from offline slow-hash scenario. (guesses < 10^10)
    # 4 - very unguessable: strong protection from offline slow-hash scenario. (guesses >= 10^10)
    passwords = ['pass', '12pass23', 'démarches ', 'démarches-simple', '{My-$3cure-p4ssWord}']
    min_complexity = PASSWORD_COMPLEXITY_FOR_ADMIN

    context 'administrateurs' do
      let(:email) { 'mail@beta.gouv.fr' }
      let(:administrateur) { build(:user, email: email, password: password, administrateur: build(:administrateur)) }

      subject do
        administrateur.save
        administrateur.errors.full_messages
      end

      context 'when password is too short' do
        let(:password) { 's' * (PASSWORD_MIN_LENGTH - 1) }

        it { expect(subject).to eq(["Le mot de passe est trop court"]) }
      end

      context 'when password is too simple' do
        passwords[0..(min_complexity - 1)].each do |password|
          let(:password) { password }

          it { expect(subject).to eq(["Le mot de passe n’est pas assez complexe"]) }
        end
      end

      context 'when password is acceptable' do
        let(:password) { passwords[min_complexity] }

        it { expect(subject).to eq([]) }
      end
    end

    context 'simple users' do
      passwords.each do |password|
        let(:user) { build(:user, email: 'some@email.fr', password: password) }
        it 'has no complexity validation' do
          user.save
          expect(user.errors.full_messages).to eq([])
        end
      end
    end
  end
end
