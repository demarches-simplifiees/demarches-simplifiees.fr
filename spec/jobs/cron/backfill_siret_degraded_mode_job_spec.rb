RSpec.describe Cron::BackfillSiretDegradedModeJob, type: :job do
  describe '.perform' do
    let(:etablissement) { create(:etablissement, adresse: nil, siret: '01234567891011') }
    let(:new_adresse) { '7 rue du puits, coye la foret' }

    context 'fix etablissement with dossier with adresse nil' do
      let(:dossier) { create(:dossier, :en_construction, etablissement: etablissement) }
      before do
        dossier
      end
      it 'works' do
        allow_any_instance_of(APIEntreprise::EtablissementAdapter).to receive(:to_params).and_return({ adresse: new_adresse })
        expect { Cron::BackfillSiretDegradedModeJob.perform_now }.to change { etablissement.reload.adresse }.from(nil).to(new_adresse)
      end
    end

    context 'fix etablisEtablissementAdapter.newsement with champs with adresse nil' do
      let(:champ_siret) { create(:champ_siret, etablissement: etablissement) }
      before do
        champ_siret
      end
      it 'works' do
        allow_any_instance_of(APIEntreprise::EtablissementAdapter).to receive(:to_params).and_return({ adresse: new_adresse })
        expect { Cron::BackfillSiretDegradedModeJob.perform_now }.to change { etablissement.reload.adresse }.from(nil).to(new_adresse)
      end
    end
  end
end
