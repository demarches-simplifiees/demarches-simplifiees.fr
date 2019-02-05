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
        expect(subject[5][:value]).to eq({ primary: "Construction, habitat, urbanisme, transport", secondary: "Patrimoine bâti et urbanisme (hors autres catégories)" })
      }
    end
  end

  context 'when a type PJ was cloned to a type champ PJ' do
    let(:original_procedure) do
      p = create(:procedure, :published)
      p.types_de_piece_justificative.create(
        libelle: "Vidéo de votre demande de subvention",
        description: "Pour optimiser vos chances, soignez la chorégraphie et privilégiez le chant polyphonique",
        lien_demarche: "https://www.dance-academy.gouv.fr",
        order_place: 0
      )
      p
    end

    let(:procedure) do
      p = original_procedure.clone(original_procedure.administrateur, false)
      p.save
      p
    end

    let(:type_pj) { original_procedure.types_de_piece_justificative.first }
    let(:migrated_type_champ) { procedure.types_de_champ.find_by(libelle: type_pj.libelle) }
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
            "id" => type_pj.id,
            "libelle" => type_pj.libelle,
            "description" => type_pj.description,
            "lien_demarche" => type_pj.lien_demarche,
            "order_place" => type_pj.order_place
          }
        ],
        pieces_justificatives: [
          {
            "content_url" => champ_pj.for_api,
            "created_at" => champ_pj.created_at.in_time_zone('UTC').iso8601(3),
            "type_de_piece_justificative_id" => type_pj.id,
            "user" => a_hash_including("id" => dossier.user.id)
          }
        ]
      )
    end

    it "does not expose the PJ as a champ" do
      expect(subject[:champs]).not_to include(a_hash_including(type_de_champ: a_hash_including(id: migrated_type_champ.id)))
    end
  end
end
