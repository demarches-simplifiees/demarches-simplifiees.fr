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

    before { instructeurs_to_remove.each { groupe_instructeur.remove(_1) } }

    it { expect(subject.body).to include('Les instructeurs int3@g, int4@g ont été retirés du groupe') }
    it { expect(subject.bcc).to match_array(['int1@g', 'int2@g']) }
  end

  describe '#notify_removed_instructeur' do
    let(:procedure) { create(:procedure) }
    let(:groupe_instructeur) do
      gi = GroupeInstructeur.create(label: 'gi1', procedure: procedure)
      gi.instructeurs << create(:instructeur, email: 'int1@g')
      gi.instructeurs << create(:instructeur, email: 'int2@g')
      gi.instructeurs << instructeur_to_remove
      gi
    end
    let(:instructeur_to_remove) { create(:instructeur, email: 'int3@g') }

    let(:current_instructeur_email) { 'toto@email.com' }

    subject { described_class.notify_removed_instructeur(groupe_instructeur, instructeur_to_remove, current_instructeur_email) }

    before { groupe_instructeur.remove(instructeur_to_remove) }

    context 'when instructeur is fully removed form procedure' do
      it { expect(subject.body).to include('Vous avez été désaffecté de la démarche') }
      it { expect(subject.to).to include('int3@g') }
      it { expect(subject.to).not_to include('int1@g', 'int2@g') }
    end

    context 'when instructeur is removed from one group but still affected to procedure' do
      let!(:groupe_instructeur_2) do
        gi2 = GroupeInstructeur.create(label: 'gi2', procedure: procedure)
        gi2.instructeurs << instructeur_to_remove
        gi2
      end

      it { expect(subject.body).to include('Vous avez été retiré du groupe « gi1 » par « toto@email.com »') }
      it { expect(subject.to).to include('int3@g') }
      it { expect(subject.to).not_to include('int1@g', 'int2@g') }
    end
  end
end
