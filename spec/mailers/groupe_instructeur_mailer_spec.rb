RSpec.describe GroupeInstructeurMailer, type: :mailer do
  describe '#add_instructeurs' do
    let(:groupe_instructeur) do
      gi = GroupeInstructeur.create(label: 'gi1', procedure: create(:procedure))
      gi.instructeurs << create(:instructeur, email: 'int1@g')
      gi.instructeurs << create(:instructeur, email: 'int2@g')
      gi
    end
    let(:instructeur_1) { create(:instructeur) }
    let(:instructeur_2) { create(:instructeur) }

    let(:instructeurs) { [instructeur_1, instructeur_2] }
    let(:current_instructeur_email) { 'toto@email.com' }

    subject { described_class.add_instructeurs(groupe_instructeur, instructeurs, current_instructeur_email) }

    it { expect(subject.body).to include('Bonjour') }
    it { expect(subject.bcc).to match_array(['int1@g', 'int2@g']) }
  end
end
