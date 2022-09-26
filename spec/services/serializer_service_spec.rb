describe SerializerService do
  let(:dossier) { create(:dossier, :en_construction) }

  describe 'champ' do
    subject { SerializerService.champ(champ) }

    describe 'type champ is siret' do
      let(:etablissement) { create(:etablissement) }
      let(:champ) { create(:champ_siret, etablissement:, dossier:) }

      it {
        is_expected.to include("stringValue" => etablissement.siret)
        expect(subject["etablissement"]).to include("siret" => etablissement.siret)
        expect(subject["etablissement"]["entreprise"]).to include("codeEffectifEntreprise" => etablissement.entreprise_code_effectif_entreprise)
      }

      context 'with entreprise_date_creation is nil' do
        let(:etablissement) { create(:etablissement, entreprise_date_creation: nil) }

        it {
          expect(subject["etablissement"]["entreprise"]).to include("nomCommercial" => etablissement.entreprise_nom_commercial)
          expect(subject["etablissement"]["entreprise"]["dateCreation"]).to be_nil
        }
      end
    end
  end
end
