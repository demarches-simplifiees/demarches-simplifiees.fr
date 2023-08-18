RSpec.describe DossierUpdateSearchTermsJob, type: :job do
  let(:dossier) { create(:dossier) }
  let(:champ_public) { dossier.champs_public.first }
  let(:champ_private) { dossier.champs_private.first }

  subject(:perform_job) { described_class.perform_now(dossier) }

  context 'with an update' do
    before do
      create(:champ_text, dossier: dossier, value: "un nouveau champ")
    end

    it { expect { perform_job }.to change { dossier.reload.search_terms }.to(/un nouveau champ/) }
  end
end
