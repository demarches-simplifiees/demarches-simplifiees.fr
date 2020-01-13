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
        expect(subject[5][:value]).to eq({ primary: 'categorie 1', secondary: 'choix 1' })
      }
    end
  end

  context 'when a type de champ PJ was cloned from a legacy PJ' do
    let(:original_pj_id) { 3 }
    let(:cloned_type_de_champ) do
      tdc = create(:type_de_champ_piece_justificative,
        libelle: "Vidéo de votre demande de subvention",
        description: "Pour optimiser vos chances, soignez la chorégraphie et privilégiez le chant polyphonique.\r\nRécupérer le formulaire vierge pour mon dossier : https://www.dance-academy.gouv.fr",
        order_place: 0)
      tdc.old_pj = { stable_id: original_pj_id }
      tdc
    end
    let(:procedure) { create(:procedure, :published, types_de_champ: [cloned_type_de_champ]) }
    let(:dossier) { create(:dossier, procedure: procedure) }
    let(:champ_pj) { dossier.champs.last }

    before do
      champ_pj.piece_justificative_file.attach(io: StringIO.new("toto"), filename: "toto.txt", content_type: "text/plain")
    end

    subject { DossierSerializer.new(dossier).serializable_hash }

    it "exposes the PJ in the legacy format" do
      is_expected.to include(
        types_de_piece_justificative: [
          {
            "id" => original_pj_id,
            "libelle" => cloned_type_de_champ.libelle,
            "description" => 'Pour optimiser vos chances, soignez la chorégraphie et privilégiez le chant polyphonique.',
            "lien_demarche" => 'https://www.dance-academy.gouv.fr',
            "order_place" => cloned_type_de_champ.order_place
          }
        ],
        pieces_justificatives: [
          {
            "content_url" => subject[:pieces_justificatives][0]["content_url"],
            "created_at" => champ_pj.created_at.in_time_zone('UTC').iso8601(3),
            "type_de_piece_justificative_id" => original_pj_id,
            "user" => a_hash_including("id" => dossier.user.id)
          }
        ]
      )
      expect(subject[:pieces_justificatives][0]["content_url"]).to match('/rails/active_storage/disk/')
    end

    it "does not expose the PJ as a champ" do
      expect(subject[:champs]).to be_empty
    end
  end
end
