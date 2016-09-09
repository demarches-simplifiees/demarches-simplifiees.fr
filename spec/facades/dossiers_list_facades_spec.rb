require 'spec_helper'

describe DossiersListFacades do

  let(:gestionnaire) { create :gestionnaire }
  let(:procedure) { create :procedure }
  let(:procedure_2) { create :procedure, libelle: 'plop' }

  before do
    create :assign_to, procedure: procedure, gestionnaire: gestionnaire
    create :assign_to, procedure: procedure_2, gestionnaire: gestionnaire

    create :preference_list_dossier,
           gestionnaire: gestionnaire,
           table: '',
           attr: 'state',
           attr_decorate: 'display_state'

    create :preference_list_dossier,
           gestionnaire: gestionnaire,
           table: '',
           attr: 'state',
           attr_decorate: 'display_state',
           procedure_id: procedure.id
  end

  describe '#preference_list_dossiers_filter' do

    subject { facade.preference_list_dossiers_filter }

    context 'when procedure is not pasted at the facade' do
      let(:facade) { described_class.new gestionnaire, 'nouveaux' }

      it { expect(subject.size).to eq 6 }
    end

    context 'when procedure is pasted at the facade' do
      let(:facade) { described_class.new gestionnaire, 'nouveaux', procedure }

      it { expect(subject.size).to eq 1 }
    end
  end

  describe '#gestionnaire_procedures_name_and_id_list' do
    let(:facade) { described_class.new gestionnaire, 'nouveaux' }

    subject { facade.gestionnaire_procedures_name_and_id_list }

    it { expect(subject.size).to eq 2 }

    it { expect(subject.first[:id]).to eq procedure.id }
    it { expect(subject.first[:libelle]).to eq procedure.libelle }

    it { expect(subject.last[:id]).to eq procedure_2.id }
    it { expect(subject.last[:libelle]).to eq procedure_2.libelle }

  end
end