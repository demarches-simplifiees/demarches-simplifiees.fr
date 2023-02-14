RSpec.describe GroupeInstructeurMailer, type: :mailer do
  describe '#notify_group_when_instructeurs_removed' do
    let(:groupe_instructeur) do
      gi = GroupeInstructeur.create(label: 'gi1', procedure: create(:procedure))
      gi.instructeurs << create(:instructeur, email: 'int1@g')
      gi.instructeurs << create(:instructeur, email: 'int2@g')
      gi.instructeurs << instructeurs_to_remove
      gi
    end
    let(:instructeur_3) { create(:instructeur, email: 'int3@g') }
    let(:instructeur_4) { create(:instructeur, email: 'int4@g') }

    let(:instructeurs_to_remove) { [instructeur_3, instructeur_4] }
    let(:current_instructeur_email) { 'toto@email.com' }

    subject { described_class.notify_group_when_instructeurs_removed(groupe_instructeur, instructeurs_to_remove, current_instructeur_email) }

    it { expect(subject.body).to include('Les instructeurs int3@g, int4@g ont été retirés du groupe') }
    it { expect(subject.bcc).to include('int1@g', 'int2@g') }
  end

  describe '#notify_removed_instructeurs' do
    let(:groupe_instructeur) do
      gi = GroupeInstructeur.create(label: 'gi1', procedure: create(:procedure))
      gi.instructeurs << create(:instructeur, email: 'int1@g')
      gi.instructeurs << create(:instructeur, email: 'int2@g')
      gi.instructeurs << instructeurs_to_remove
      gi
    end
    let(:instructeur_3) { create(:instructeur, email: 'int3@g') }
    let(:instructeur_4) { create(:instructeur, email: 'int4@g') }

    let(:instructeurs_to_remove) { [instructeur_3, instructeur_4] }
    let(:current_instructeur_email) { 'toto@email.com' }

    subject { described_class.notify_removed_instructeurs(groupe_instructeur, instructeurs_to_remove, current_instructeur_email) }

    it { expect(subject.body).to include('ous avez été retiré du groupe « gi1 » par « toto@email.com »') }
    it { expect(subject.bcc).to match_array(['int3@g', 'int4@g']) }
    it { expect(subject.bcc).not_to match_array(['int1@g', 'int2@g']) }
  end
end
