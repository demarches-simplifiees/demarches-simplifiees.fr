# frozen_string_literal: true

RSpec.describe GroupeInstructeurMailer, type: :mailer do
  describe '#notify_removed_instructeur' do
    let(:procedure) { create(:procedure) }
    let(:groupe_instructeur) do
      gi = GroupeInstructeur.create(label: 'gi1', procedure: procedure)
      gi.instructeurs << create(:instructeur, email: 'int1@g.fr')
      gi.instructeurs << create(:instructeur, email: 'int2@g.fr')
      gi.instructeurs << instructeur_to_remove
      gi
    end
    let(:instructeur_to_remove) { create(:instructeur, email: 'int3@g.fr') }

    let(:current_instructeur_email) { 'toto@email.com' }

    subject { described_class.notify_removed_instructeur(groupe_instructeur, instructeur_to_remove, current_instructeur_email) }

    before { groupe_instructeur.remove(instructeur_to_remove) }

    context 'when instructeur is fully removed form procedure' do
      it { expect(subject.body).to include('Vous avez été désaffecté(e) de la démarche') }
      it { expect(subject.to).to include('int3@g.fr') }
      it { expect(subject.to).not_to include('int1@g.fr', 'int2@g.fr') }
    end

    context 'when instructeur is removed from one group but still affected to procedure' do
      let!(:groupe_instructeur_2) do
        gi2 = GroupeInstructeur.create(label: 'gi2', procedure: procedure)
        gi2.instructeurs << instructeur_to_remove
        gi2
      end

      it { expect(subject.body).to include('Vous avez été retiré(e) du groupe « gi1 » par « toto@email.com »') }
      it { expect(subject.to).to include('int3@g.fr') }
      it { expect(subject.to).not_to include('int1@g.fr', 'int2@g.fr') }
    end
  end

  describe '#notify_added_instructeurs' do
    let(:procedure) { create(:procedure) }

    let(:instructeurs_to_add) { [create(:instructeur, email: 'int3@g.fr'), create(:instructeur, email: 'int4@g.fr')] }

    let(:current_instructeur_email) { 'toto@email.com' }

    subject { described_class.notify_added_instructeurs(procedure.defaut_groupe_instructeur, instructeurs_to_add, current_instructeur_email) }

    before { instructeurs_to_add.each { procedure.defaut_groupe_instructeur.add(_1) } }

    context 'when there is only one group on procedure' do
      it { expect(subject.body).to include('Vous avez été affecté(e) à la démarche') }
      it { expect(subject.bcc).to match_array(['int3@g.fr', 'int4@g.fr']) }
    end

    context 'when there are many groups on procedure' do
      let!(:groupe_instructeur_2) do
        GroupeInstructeur.create(label: 'gi2', procedure: procedure)
      end
      it { expect(subject.body).to include('Vous avez été ajouté(e) au groupe') }
      it { expect(subject.bcc).to match_array(['int3@g.fr', 'int4@g.fr']) }
    end
  end
end
