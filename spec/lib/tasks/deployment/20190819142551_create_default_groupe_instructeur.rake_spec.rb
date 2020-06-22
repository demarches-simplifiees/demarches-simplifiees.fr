describe '20190819142551_create_default_groupe_instructeur.rake' do
  let(:rake_task) { Rake::Task['after_party:create_default_groupe_instructeur'] }

  subject { rake_task.invoke }
  after { rake_task.reenable }

  context 'with a procedure without gi' do
    let!(:procedure_without_gi) { create(:procedure) }

    before do
      procedure_without_gi.groupe_instructeurs.destroy_all
    end

    it do
      expect(procedure_without_gi.groupe_instructeurs).to be_empty
      subject
      expect(procedure_without_gi.reload.groupe_instructeurs.pluck(:label)).to eq(['défaut'])
    end
  end

  context 'with a procedure discarded without gi' do
    let!(:procedure_discarded_without_gi) { create(:procedure, :discarded) }

    before do
      procedure_discarded_without_gi.groupe_instructeurs.destroy_all
    end

    it do
      expect(procedure_discarded_without_gi.groupe_instructeurs).to be_empty
      subject
      expect(procedure_discarded_without_gi.reload.groupe_instructeurs.pluck(:label)).to eq(['défaut'])
    end
  end

  context 'with a procedure with a gi' do
    let!(:procedure_with_gi) { create(:procedure) }

    it do
      gi = procedure_with_gi.groupe_instructeurs.first
      expect(gi).to be_present
      subject
      expect(procedure_with_gi.reload.groupe_instructeurs).to eq([gi])
    end
  end
end
