require 'spec_helper'

describe DossiersListFacades do

  let(:gestionnaire) { create :gestionnaire }
  let(:procedure) { create :procedure }

  before do
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
end