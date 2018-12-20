describe '20181219164523_clone_service_for_transferred_procedures.rake' do
  let(:rake_task) { Rake::Task['after_party:clone_service_for_transferred_procedures'] }

  subject do
    rake_task.invoke
  end

  after do
    rake_task.reenable
  end

  context 'procedures from different admins share the same service' do
    let(:admin1) { create(:administrateur) }
    let(:admin2) { create(:administrateur) }
    let(:service) { create(:service, administrateur: admin1) }
    let!(:procedure1) { create(:procedure, service: service, administrateur: admin1) }
    let!(:procedure2) { create(:procedure, service: service, administrateur: admin2) }
    let!(:procedure3) { create(:procedure, service: service, administrateur: admin2) }

    it 'clones service for procedure2 & procedure3' do
      subject
      expect(procedure1.reload.service).not_to eq(procedure2.reload.service)
      expect(procedure1.reload.service).not_to eq(procedure3.reload.service)
      expect(procedure2.reload.service).to eq(procedure3.reload.service)
    end

    it 'does nothing for procedure1' do
      subject
      expect(procedure1.reload.service).to eq(service)
    end
  end
end
