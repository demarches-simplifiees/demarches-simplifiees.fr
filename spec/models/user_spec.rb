describe User, type: :model do
  describe '#after_confirmation' do
    let(:email) { 'mail@beta.gouv.fr' }
    let!(:invite) { create(:invite, email: email) }
    let!(:invite2) { create(:invite, email: email) }
    let(:user) do
      create(:user,
        email: email,
        password: 'my-s3cure-p4ssword',
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
      before { create(:user, email: email, password: 'my-s3cure-p4ssword') }

      it 'keeps the previous password' do
        user = subject
        expect(user.valid_password?('my-s3cure-p4ssword')).to be true
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
    let(:administrateur) { create(:administrateur) }
    let(:instructeur) { create(:instructeur) }
    let(:expert) { create(:expert) }

    subject { user.can_be_deleted? }

    context 'when the user has a dossier in instruction' do
      let!(:dossier) { create(:dossier, :en_instruction, user: user) }

      it { is_expected.to be true }
    end

    context 'when the user has no dossier in instruction' do
      it { is_expected.to be true }
    end

    context 'when the user is an administrateur' do
      it 'cannot be deleted' do
        expect(administrateur.user.can_be_deleted?).to be_falsy
      end
    end

    context 'when the user is an instructeur' do
      it 'cannot be deleted' do
        expect(instructeur.user.can_be_deleted?).to be_falsy
      end
    end

    context 'when the user is an expert' do
      it 'cannot be deleted' do
        expect(expert.user.can_be_deleted?).to be_falsy
      end
    end
  end

  describe '#delete_and_keep_track_dossiers_also_delete_user' do
    let(:super_admin) { create(:super_admin) }
    let(:user) { create(:user) }

    context 'without a dossier with processing strted' do
      let!(:dossier_en_construction) { create(:dossier, :en_construction, user: user) }
      let!(:dossier_brouillon) { create(:dossier, user: user) }

      context 'without a discarded dossier' do
        it "keep track of dossiers and delete user" do
          user.delete_and_keep_track_dossiers_also_delete_user(super_admin)

          expect(DeletedDossier.find_by(dossier_id: dossier_en_construction)).to be_present
          expect(DeletedDossier.find_by(dossier_id: dossier_brouillon)).to be_nil
          expect(User.find_by(id: user.id)).to be_nil
        end
      end

      context 'with a deleted dossier' do
        let(:dossier_to_delete) { create(:dossier, :en_construction, user: user) }
        let!(:dossier_from_another_user) { create(:dossier, :en_construction, user: create(:user)) }

        it "keep track of dossiers and delete user" do
          dossier_to_delete.hide_and_keep_track!(user, :user_request)
          user.delete_and_keep_track_dossiers_also_delete_user(super_admin)

          expect(DeletedDossier.find_by(dossier_id: dossier_en_construction)).to be_present
          expect(DeletedDossier.find_by(dossier_id: dossier_brouillon)).to be_nil
          expect(Dossier.find_by(id: dossier_from_another_user.id)).to be_present
          expect(User.find_by(id: user.id)).to be_nil
        end
      end
    end

    context 'with dossiers with processing started' do
      let!(:dossier_en_instruction) { create(:dossier, :en_instruction, user: user) }
      let!(:dossier_termine) { create(:dossier, :accepte, user: user) }

      it "keep track of dossiers and delete user" do
        user.delete_and_keep_track_dossiers_also_delete_user(super_admin)

        expect(dossier_en_instruction.reload).to be_present
        expect(dossier_en_instruction.user).to be_nil
        expect(dossier_en_instruction.user_email_for(:display)).to eq(user.email)
        expect { dossier_en_instruction.user_email_for(:notification) }.to raise_error(RuntimeError)

        expect(dossier_termine.reload).to be_present
        expect(dossier_termine.user).to be_nil
        expect(dossier_termine.user_email_for(:display)).to eq(user.email)
        expect(dossier_termine.valid?).to be_truthy
        expect(dossier_termine.france_connect_information).to be_nil
        expect { dossier_termine.user_email_for(:notification) }.to raise_error(RuntimeError)

        expect(User.find_by(id: user.id)).to be_nil
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
    passwords = ['password', '12pass23', 'démarches ', 'démarches-simple', '{My-$3cure-p4ssWord}']
    min_complexity = PASSWORD_COMPLEXITY_FOR_ADMIN

    subject do
      user.valid?
      user.errors.full_messages
    end

    context 'for administrateurs' do
      let(:user) { build(:user, email: 'admin@exemple.fr', password: password, administrateur: build(:administrateur, user: nil)) }

      context 'when the password is too short' do
        let(:password) { 's' * (PASSWORD_MIN_LENGTH - 1) }

        it 'reports an error about password length (but not about complexity)' do
          expect(subject).to eq(["Le champ « Mot de passe » est trop court. Saisir un mot de passe avec au moins 8 caractères"])
        end
      end

      passwords[0..(min_complexity - 1)].each do |simple_password|
        context 'when the password is long enough, but too simple' do
          let(:password) { simple_password }

          it { expect(subject).to eq(["Le champ « Mot de passe » n’est pas assez complexe. Saisir un mot de passe plus complexe"]) }
        end
      end

      context 'when the password is long and complex' do
        let(:password) { passwords[min_complexity] }

        it { expect(subject).to be_empty }
      end
    end

    context 'for simple users' do
      let(:user) { build(:user, email: 'user@exemple.fr', password: password) }

      context 'when the password is too short' do
        let(:password) { 's' * (PASSWORD_MIN_LENGTH - 1) }

        it 'reports an error about password length (but not about complexity)' do
          expect(subject).to eq(["Le champ « Mot de passe » est trop court. Saisir un mot de passe avec au moins 8 caractères"])
        end
      end

      context 'when the password is long enough, but simple' do
        let(:password) { 'simple-password' }

        it 'doesn’t enforce the password complexity' do
          expect(subject).to be_empty
        end
      end
    end
  end

  describe '#merge' do
    let(:old_user) { create(:user) }
    let(:targeted_user) { create(:user) }

    subject { targeted_user.merge(old_user) }
    context 'merge myself' do
      it 'fails' do
        expect { old_user.merge(old_user) }.to raise_error 'Merging same user, no way'
      end
    end
    context 'and the old account has some stuff' do
      let!(:dossier) { create(:dossier, user: old_user) }
      let!(:hidden_dossier) { create(:dossier, user: old_user, hidden_by_user_at: 1.hour.ago) }
      let!(:invite) { create(:invite, user: old_user) }
      let!(:merge_log) { MergeLog.create(user: old_user, from_user_id: 1, from_user_email: 'a') }

      it 'transfers the dossier' do
        subject

        expect(targeted_user.dossiers).to contain_exactly(dossier, hidden_dossier)
        expect(targeted_user.invites).to match([invite])
        expect(targeted_user.merge_logs.first).to eq(merge_log)

        added_merge_log = targeted_user.merge_logs.last
        expect(added_merge_log.from_user_id).to eq(old_user.id)
        expect(added_merge_log.from_user_email).to eq(old_user.email)
      end
    end

    context 'and the old account belongs to an instructeur, expert and administrateur' do
      let!(:expert) { create(:expert, user: old_user) }
      let!(:administrateur) { create(:administrateur, user: old_user) }
      let!(:instructeur) { old_user.instructeur }

      it 'transfers instructeur account' do
        subject
        targeted_user.reload

        expect(targeted_user.instructeur).to match(instructeur)
        expect(targeted_user.administrateur).to match(administrateur)
        expect(targeted_user.expert).to match(expert)
      end

      context 'and the targeted account owns an instructeur and expert as well' do
        let!(:targeted_administrateur) { create(:administrateur, user: targeted_user) }
        let!(:targeted_instructeur) { targeted_user.instructeur }
        let!(:targeted_expert) { create(:expert, user: targeted_user) }

        it 'merge the account' do
          expect(targeted_instructeur).to receive(:merge).with(instructeur)
          expect(targeted_expert).to receive(:merge).with(expert)
          expect(targeted_administrateur).to receive(:merge).with(administrateur)

          subject

          expect { instructeur.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect { expert.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect { administrateur.reload }.to raise_error(ActiveRecord::RecordNotFound)
          expect { old_user.reload }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end

    context 'and the old account had targeted_user_links' do
      let(:expert) { create(:expert, user: old_user) }
      let(:expert_procedure) { create(:experts_procedure, expert: expert) }
      let!(:targeted_user_link) { create(:targeted_user_link, user: old_user, target_model: create(:avis, experts_procedure: expert_procedure)) }

      it 'transfers the targeted_user_link' do
        subject
        targeted_user.reload
        expect(targeted_user.targeted_user_links).to include(targeted_user_link)
      end
    end
  end
end
