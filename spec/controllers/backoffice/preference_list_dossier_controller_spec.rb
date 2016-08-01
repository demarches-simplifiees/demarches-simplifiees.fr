require 'spec_helper'

describe Backoffice::PreferenceListDossierController, type: :controller do
  let(:gestionnaire) { create :gestionnaire }
  let(:libelle) { 'Plop' }
  let(:table) { 'plip' }
  let(:attr) { 'plap' }
  let(:attr_decorate) { 'plup' }
  let(:bootstrap_lg) { 'plyp' }

  before do
    sign_in gestionnaire
  end

  describe '#POST add' do
    subject { post :add, libelle: libelle,
                   table: table,
                   attr: attr,
                   attr_decorate: attr_decorate,
                   bootstrap_lg: bootstrap_lg }

    it { expect(subject.status).to eq 200 }
    it { expect { subject }.to change(PreferenceListDossier, :count).by(1) }

    describe 'attributs' do
      let(:last) { PreferenceListDossier.last }

      before do
        subject
      end

      it { expect(last.libelle).to eq libelle }
      it { expect(last.table).to eq table }
      it { expect(last.attr).to eq attr }
      it { expect(last.attr_decorate).to eq attr_decorate }
      it { expect(last.bootstrap_lg).to eq bootstrap_lg }
      it { expect(last.order).to be_nil }
      it { expect(last.filter).to be_nil }
      it { expect(last.gestionnaire).to eq gestionnaire }
    end
  end

  describe '#DELETE delete' do
    let!(:pref) { create :preference_list_dossier }

    subject { delete :delete, pref_id: pref.id }

    it { expect(subject.status).to eq 200 }
    it { expect { subject }.to change(PreferenceListDossier, :count).by(-1) }
  end
end
