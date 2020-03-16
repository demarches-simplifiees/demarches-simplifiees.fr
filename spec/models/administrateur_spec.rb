require 'spec_helper'

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
  end

  # describe '#password_complexity' do
  #   let(:email) { 'mail@beta.gouv.fr' }
  #   let(:passwords) { ['pass', '12pass23', 'démarches ', 'démarches-simple', 'démarches-simplifiées-pwd'] }
  #   let(:administrateur) { build(:administrateur, email: email, password: password) }
  #   let(:min_complexity) { PASSWORD_COMPLEXITY_FOR_ADMIN }

  #   subject do
  #     administrateur.save
  #     administrateur.errors.full_messages
  #   end

  #   context 'when password is too short' do
  #     let(:password) { 's' * (PASSWORD_MIN_LENGTH - 1) }

  #     it { expect(subject).to eq(["Le mot de passe est trop court"]) }
  #   end

  #   context 'when password is too simple' do
  #     let(:password) { passwords[min_complexity - 1] }

  #     it { expect(subject).to eq(["Le mot de passe n'est pas assez complexe"]) }
  #   end

  #   context 'when password is acceptable' do
  #     let(:password) { passwords[min_complexity] }

  #     it { expect(subject).to eq([]) }
  #   end
  # end
end
