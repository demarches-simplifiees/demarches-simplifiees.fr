require 'spec_helper'

describe AdminProceduresShowFacades do
  let!(:procedure) { create(:procedure) }

  let!(:dossier_0) { create(:dossier,  procedure: procedure, state: 'draft') }
  let!(:dossier_1) { create(:dossier,  procedure: procedure, state: 'initiated') }
  let!(:dossier_2) { create(:dossier,  procedure: procedure, state: 'replied') }
  let!(:dossier_6) { create(:dossier,  procedure: procedure, archived: true, state: 'initiated') }
  let!(:dossier_7) { create(:dossier,  procedure: procedure, state: 'updated') }

  subject { AdminProceduresShowFacades.new procedure }

  describe '.procedure' do
    subject { super().procedure }

    it { is_expected.to eq(procedure) }
  end

  describe '.dossiers' do
    subject { super().dossiers }

    it { expect(subject.size).to eq(4)  }
  end

  describe '.dossiers_for_pie_highchart' do
    subject { super().dossiers_for_pie_highchart }

    it { expect(subject).to eq({ 'En construction' => 3 }) }
  end

  describe '.dossiers_archived_by_state_total' do
    subject { super().dossiers_archived_by_state_total }

    it { expect(subject.size).to eq(1)  }

    it { expect(subject.first.state).to eq('initiated')  }
    it { expect(subject.first.total).to eq(1) }
  end

  describe 'dossiers_archived_total' do
    subject { super().dossiers_archived_total }

    it { is_expected.to eq(1) }
  end

  describe 'dossiers_total' do
    subject { super().dossiers_total }

    it { is_expected.to eq(4) }
  end

  describe 'dossiers_waiting_gestionnaire_total' do
    subject { super().dossiers_waiting_gestionnaire_total }

    it { is_expected.to eq(1) }
  end

  describe 'dossiers_waiting_user_total' do
    subject { super().dossiers_waiting_user_total }

    it { is_expected.to eq(1) }
  end

  describe 'dossiers_termine_total' do
    subject { super().dossiers_termine_total }

    it { is_expected.to eq(0) }
  end
end
