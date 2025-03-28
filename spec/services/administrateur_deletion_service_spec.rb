describe AdministrateurDeletionService do
  let(:super_admin) { create(:super_admin) }
  let(:admin) { administrateurs(:default_admin) }
  let(:service) { create(:service, administrateur: admin) }
  let(:other_admin) { create(:administrateur) }
  let(:procedure) { create(:procedure, service: service, administrateurs: [admin, other_admin]) }
  let(:owned_procedure_service) { create(:service, administrateur: admin) }
  let(:owned_procedure) { create(:procedure, service: owned_procedure_service, administrateurs: [admin]) }

  describe '' do
    subject { AdministrateurDeletionService.new(super_admin, admin).call }

    context 'when admin can be deleted' do
      it 'removes admin procedures without dossiers' do
        owned_procedure
        subject
        expect(Procedure.find_by(id: owned_procedure.id)).to be_nil
      end

      it 'removes service admins without procedure' do
        owned_procedure
        subject
        expect(Service.find_by(id: owned_procedure_service.id)).to be_nil
      end

      it 'transfer services to other admin' do
        procedure
        subject
        expect(procedure.service.administrateur).to eq other_admin
      end

      it 'deletes admin' do
        procedure
        owned_procedure
        subject
        expect(Administrateur.find_by(id: admin.id)).to be_nil
      end
    end

    context 'when admin has some procedures with dossiers and only one admin' do
      let(:owned_procedure_with_dossier) { create(:procedure_with_dossiers, service: owned_procedure_service, administrateurs: [admin]) }

      it "doesn't destroy admin" do
        owned_procedure_with_dossier
        subject
        expect(Administrateur.find_by(id: admin.id)).to eq admin
        expect(subject.failure).to eq :cannot_be_deleted
      end
    end

    context 'when admin has one discarded procedure without dossiers and only one admin' do
      let(:owned_procedure_without_dossier) { create(:procedure, service: owned_procedure_service, administrateurs: [admin]) }

      before { owned_procedure_without_dossier.discard! }

      it "deletes admin" do
        subject
        expect(Administrateur.find_by(id: admin.id)).to be_nil
      end
    end

    context "when there is a failure" do
      it 'rollbacks' do
        allow_any_instance_of(Service).to receive(:update).and_return(false)
        procedure
        owned_procedure
        subject
        expect(subject.failure).to eq :still_services
        expect(admin.procedures.count).to eq 2
        expect(procedure.administrateurs).to include(admin)
      end
    end
  end
end
