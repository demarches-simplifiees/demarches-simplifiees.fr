describe Administrateur, type: :model do
  let(:administration) { create(:administration) }

  describe 'assocations' do
    it { is_expected.to have_and_belong_to_many(:instructeurs) }
    it { is_expected.to have_many(:procedures) }
  end

  describe "#renew_api_token" do
    let!(:administrateur) { create(:administrateur) }
    let!(:token) { administrateur.renew_api_token }

    it { expect(BCrypt::Password.new(administrateur.encrypted_token)).to eq(token) }

    context 'when it s called twice' do
      let!(:new_token) { administrateur.renew_api_token }

      it { expect(new_token).not_to eq(token) }
    end
  end

  describe "#can_be_deleted?" do
    subject { administrateur.can_be_deleted? }

    context "when the administrateur's procedures have other administrateurs" do
      let!(:administrateur) { create(:administrateur) }
      let!(:autre_administrateur) { create(:administrateur) }
      let!(:procedure) { create(:procedure, administrateurs: [administrateur, autre_administrateur]) }

      it { is_expected.to be true }
    end

    context "when the administrateur has a procedure where they is the only admin" do
      let!(:administrateur) { create(:administrateur) }
      let!(:procedure) { create(:procedure, administrateurs: [administrateur]) }

      it { is_expected.to be false }
    end

    context "when the administrateur has no procedure" do
      let!(:administrateur) { create(:administrateur) }

      it { is_expected.to be true }
    end
  end

  describe '#delete_and_transfer_services' do
    let!(:administrateur) { create(:administrateur) }
    let!(:autre_administrateur) { create(:administrateur) }
    let!(:procedure) { create(:procedure, :with_service, administrateurs: [administrateur, autre_administrateur]) }
    let(:service) { procedure.service }

    it "delete and transfer services to other admin" do
      service.update(administrateur: administrateur)
      administrateur.delete_and_transfer_services

      expect(Administrateur.find_by(id: administrateur.id)).to be_nil
      expect(service.reload.administrateur).to eq(autre_administrateur)
    end

    it "delete service if not associated to procedures" do
      service_without_procedure = create(:service, administrateur: administrateur)
      administrateur.delete_and_transfer_services

      expect(Service.find_by(id: service_without_procedure.id)).to be_nil
      expect(Administrateur.find_by(id: administrateur.id)).to be_nil
    end

    it "does not delete service if associated to an archived procedure" do
      service.update(administrateur: administrateur)
      procedure.discard!
      administrateur.delete_and_transfer_services

      expect(Service.find_by(id: procedure.service.id)).not_to be_nil
      expect(Administrateur.find_by(id: administrateur.id)).to be_nil
    end
  end

  describe '#merge' do
    let(:new_admin) { create(:administrateur) }
    let(:old_admin) { create(:administrateur) }

    subject { new_admin.merge(old_admin) }

    context 'when the old admin does not exist' do
      let(:old_admin) { nil }

      it { expect { subject }.not_to raise_error }
    end

    context 'when the old admin has a procedure' do
      let(:procedure) { create(:procedure) }

      before do
        old_admin.procedures << procedure
        subject
        [new_admin, old_admin].map(&:reload)
      end

      it 'transfers the procedure' do
        expect(new_admin.procedures).to match_array(procedure)
        expect(old_admin.procedures).to be_empty
      end
    end

    context 'when both admins share a procedure' do
      let(:procedure) { create(:procedure) }

      before do
        new_admin.procedures << procedure
        old_admin.procedures << procedure
        subject
        [new_admin, old_admin].map(&:reload)
      end

      it 'removes the procedure from the old one' do
        expect(old_admin.procedures).to be_empty
      end
    end

    context 'when the old admin has a service' do
      let(:service) { create(:service, administrateur: old_admin) }

      before do
        service
        subject
        [new_admin, old_admin].map(&:reload)
      end

      it 'transfers the service' do
        expect(new_admin.services).to match_array(service)
      end
    end

    context 'when the old admin has an instructeur' do
      let(:instructeur) { create(:instructeur) }

      before do
        old_admin.instructeurs << instructeur
        subject
        [new_admin, old_admin].map(&:reload)
      end

      it 'transfers the instructeur' do
        expect(new_admin.instructeurs).to match_array(instructeur)
        expect(old_admin.instructeurs).to be_empty
      end
    end

    context 'when both admins share an instructeur' do
      let(:instructeur) { create(:instructeur) }

      before do
        old_admin.instructeurs << instructeur
        new_admin.instructeurs << instructeur
        subject
        [new_admin, old_admin].map(&:reload)
      end

      it 'transfers the instructeur' do
        expect(new_admin.instructeurs).to match_array(instructeur)
        expect(old_admin.instructeurs).to be_empty
      end
    end
  end
end
