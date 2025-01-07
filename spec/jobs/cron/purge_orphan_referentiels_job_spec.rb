# frozen_string_literal: true

RSpec.describe Cron::PurgeOrphanReferentielsJob, type: :job do
  let!(:used_referentiel) { create(:csv_referentiel) }
  let!(:orphan_referentiel) { create(:csv_referentiel) }
  let!(:type_de_champ) { create(:type_de_champ, referentiel_id: used_referentiel.id) }

  subject(:perform_job) { described_class.perform_now }

  describe '#perform' do
    it { expect { subject }.to change(Referentiel, :count).by(-1) }
  end
end
