# frozen_string_literal: true

describe Cron::FallbackFetchCadastreRealGeometryJob, type: :job do
  describe '#perform' do
    let(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :carte, options: { cadastres: true } }]) }
    let(:dossier) { create(:dossier, procedure: procedure) }
    let(:champ) { dossier.champs.first }

    context 'when cadastre lookup works' do
      it 'processes pending geo areas' do
        create(:geo_area, :selection_utilisateur, cadastre_state: nil, champ:)
        create(:geo_area, :cadastre, cadastre_state: :cadastre_fetched, champ:)
        enqueued_geoarea = create(:geo_area, :cadastre, cadastre_state: nil, champ:)
        expect { described_class.perform_now }.to have_enqueued_job(FetchCadastreRealGeometryJob).with(enqueued_geoarea)
      end
    end
  end
end
