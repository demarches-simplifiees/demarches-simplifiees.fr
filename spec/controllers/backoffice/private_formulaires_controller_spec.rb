require 'spec_helper'

describe Backoffice::PrivateFormulairesController, type: :controller do
  let(:gestionnaire) { create :gestionnaire }
  let(:dossier) { create :dossier, state: :en_construction }
  let(:dossier_champs_first) { 'plop' }

  before do
    create :assign_to, procedure_id: dossier.procedure.id, gestionnaire_id: gestionnaire.id

    sign_in gestionnaire
  end

  describe '#PATCH update' do
    subject { patch :update,
      params: {
        dossier_id: dossier.id,
        champs: {
          "'#{dossier.champs_private.first.id}'" => dossier_champs_first
        }
      }
    }

    before do
      subject
    end

    it { expect(response.status).to eq 200 }
    it { expect(Dossier.find(dossier.id).champs_private.first.value).to eq dossier_champs_first }
    it { expect(flash[:notice]).to be_present }
  end
end
