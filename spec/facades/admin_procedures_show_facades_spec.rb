require 'spec_helper'

describe AdminProceduresShowFacades do
  let!(:procedure) { create(:procedure) }

  let!(:dossier_0) { create(:dossier,  procedure: procedure, state: 'brouillon') }
  let!(:dossier_1) { create(:dossier,  procedure: procedure, state: 'en_construction') }
  let!(:dossier_2) { create(:dossier,  procedure: procedure, state: 'en_construction') }
  let!(:dossier_6) { create(:dossier,  procedure: procedure, archived: true, state: 'en_construction') }

  subject { AdminProceduresShowFacades.new procedure }

  describe '#procedure' do
    subject { super().procedure }

    it { is_expected.to eq(procedure) }
  end
end
