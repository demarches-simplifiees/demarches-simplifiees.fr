RSpec.describe GroupeInstructeurMailer, type: :mailer do
  describe '#remove_instructeurs' do
    let(:groupe_instructeur) do
      gi = GroupeInstructeur.create(label: 'gi1', procedure: create(:procedure))
      gi.instructeurs << create(:instructeur, email: 'int1@g')
      gi.instructeurs << create(:instructeur, email: 'int2@g')
      gi.instructeurs << instructeurs_to_remove
      gi
    end
    let(:instructeur_1) { create(:instructeur, email: 'int3@g') }
    let(:instructeur_2) { create(:instructeur, email: 'int4@g') }

    let(:instructeurs_to_remove) { [instructeur_1, instructeur_2] }
    let(:current_instructeur_email) { 'toto@email.com' }

    subject { described_class.remove_instructeurs(groupe_instructeur, instructeurs_to_remove, current_instructeur_email) }

    it { expect(subject.body).to include('Les instructeurs int3@g, int4@g ont été retirés du groupe') }
    it { expect(subject.bcc).to match_array(['int1@g', 'int2@g', 'int3@g', 'int4@g']) }
  end
end
