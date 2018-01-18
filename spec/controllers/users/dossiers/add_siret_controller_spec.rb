require 'spec_helper'

describe Users::Dossiers::AddSiretController, type: :controller do
  describe '#GET show' do
    let(:dossier) { create :dossier }

    before do
      sign_in dossier.user
    end

    subject { get :show, params: { dossier_id: dossier.id } }

    context 'when dossier is not attached at a procedure with individual siret attribut' do
      it { is_expected.to redirect_to users_dossiers_path }
    end

    context 'when dossier is  attached at a procedure with individual siret attribut' do
      let(:procedure) { create :procedure, individual_with_siret: true }
      let(:dossier) { create :dossier, procedure: procedure }

      it { expect(subject.status).to eq 200 }
    end
  end
end
