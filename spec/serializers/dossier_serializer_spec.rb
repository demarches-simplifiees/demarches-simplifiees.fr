describe DossierSerializer do
  describe '#attributes' do
    subject { DossierSerializer.new(dossier).serializable_hash }

    context 'when the dossier is en_construction' do
      let(:dossier) { create(:dossier, :en_construction) }

      it { is_expected.to include(initiated_at: dossier.en_construction_at) }
      it { is_expected.to include(state: 'initiated') }
    end

    context 'when the dossier is en instruction' do
      let(:dossier) { create(:dossier, :en_instruction) }

      it { is_expected.to include(received_at: dossier.en_instruction_at) }
    end

    context 'champs' do
      subject { super()[:champs] }

      let(:dossier) { create(:dossier, :en_construction, procedure: create(:procedure, :published, :with_type_de_champ)) }

      before do
        dossier.champs << create(:champ_carte)
        dossier.champs << create(:champ_siret)
        dossier.champs << create(:champ_integer_number)
        dossier.champs << create(:champ_decimal_number)
        dossier.champs << create(:champ_linked_drop_down_list)
      end

      it {
        expect(subject.size).to eq(6)

        expect(subject[0][:type_de_champ][:type_champ]).to eq(TypeDeChamp.type_champs.fetch(:text))
        expect(subject[1][:type_de_champ][:type_champ]).to eq(TypeDeChamp.type_champs.fetch(:carte))
        expect(subject[2][:type_de_champ][:type_champ]).to eq(TypeDeChamp.type_champs.fetch(:siret))

        expect(subject[1][:geo_areas].size).to eq(0)
        expect(subject[2][:etablissement]).to be_present
        expect(subject[2][:entreprise]).to be_present

        expect(subject[3][:value]).to eq(42)
        expect(subject[4][:value]).to eq(42.1)
        expect(subject[5][:value]).to eq({ primary: nil, secondary: nil })
      }
    end
  end
end
