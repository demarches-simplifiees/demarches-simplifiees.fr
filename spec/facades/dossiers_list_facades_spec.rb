require 'spec_helper'

describe DossiersListFacades do

  let(:gestionnaire) { create :gestionnaire }
  let(:procedure) { create :procedure, libelle: 'Ma procédure' }
  let(:procedure_2) { create :procedure, libelle: 'Ma seconde procédure' }

  let!(:preference) { create :preference_list_dossier,
    gestionnaire: gestionnaire,
    table: nil,
    attr: 'state',
    attr_decorate: 'display_state'
  }

  let!(:preference_2) { create :preference_list_dossier,
    gestionnaire: gestionnaire,
    table: 'champs',
    attr: 'state',
    attr_decorate: 'display_state',
    procedure_id: procedure.id
  }

  before do
    create :assign_to, procedure: procedure, gestionnaire: gestionnaire
    create :assign_to, procedure: procedure_2, gestionnaire: gestionnaire
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

    it { expect(subject.first).to eq({ id: procedure.id, libelle: procedure.libelle, unread_notifications: 0 }) }
    it { expect(subject.last).to eq({ id: procedure_2.id, libelle: procedure_2.libelle, unread_notifications: 0 }) }
  end

  describe '#active_filter?' do
    let(:table) { nil }
    let(:filter) { nil }
    let(:facade) { described_class.new gestionnaire, 'nouveaux', procedure_2 }

    let!(:preference) { create :preference_list_dossier,
      gestionnaire: gestionnaire,
      table: table,
      attr: 'state',
      attr_decorate: 'display_state',
      filter: filter,
      procedure_id: procedure_id
    }

    subject { facade.active_filter? preference }

    context 'when gestionnaire does not have select a procedure' do
      let(:procedure_2) { nil }
      let(:procedure_id) { nil }

      it { expect(preference.procedure).to be_nil }
      it { is_expected.to be_truthy }
    end

    context 'when gestionnaire have select a procedure' do
      let(:procedure_id) { procedure_2.id }

      it { expect(preference.procedure).not_to be_nil }

      context 'when preference is not a champs filter' do
        let(:table) { 'entreprises' }

        it { is_expected.to be_truthy }
      end

      context 'when gestionnaire have an existant filter with a champ' do
        let(:table) { 'champs' }
        let(:filter) { 'plop' }

        context 'when the preference is the existant champ filter' do
          it { is_expected.to be_truthy }
        end

        context 'when the preference is not the existant champ filter' do
          let(:preference) { preference_2 }

          before do
            create :preference_list_dossier,
              gestionnaire: gestionnaire,
              table: 'champs',
              attr: 'state',
              attr_decorate: 'display_state',
              filter: 'plop',
              procedure_id: procedure_id
          end

          it { is_expected.to be_falsey }
        end
      end

      context 'when gestionnaire does not have an existant filter with a champ' do
        let(:table) { nil }
        let(:filter) { 'plop' }

        context 'when the preference is the existant preference filter' do
          it { is_expected.to be_truthy }
        end

        context 'when the preference is not the existant preference filter' do
          let(:preference) { preference_2 }

          it { is_expected.to be_truthy }
        end
      end
    end
  end
end
