describe ProcedureSerializer do
  describe '#attributes' do
    subject { ProcedureSerializer.new(procedure).serializable_hash }
    let(:procedure) { create(:procedure, :published) }

    it {
      is_expected.to include(link: "http://test.host/commencer/#{procedure.path}")
      is_expected.to include(state: "publiee")
    }
  end

  context 'when a type PJ was cloned to a type champ PJ' do
    let(:original_pj_id) { 3 }
    let(:cloned_type_de_champ) do
      {
        type: :piece_justificative,
        libelle: "Vidéo de votre demande de subvention",
        description: "Pour optimiser vos chances, soignez la chorégraphie et privilégiez le chant polyphonique.\r\nRécupérer le formulaire vierge pour mon dossier : https://www.dance-academy.gouv.fr",
        old_pj: { stable_id: original_pj_id }
      }
    end
    let(:procedure) { create(:procedure, :published, types_de_champ_public: [cloned_type_de_champ]) }

    subject { ProcedureSerializer.new(procedure).serializable_hash }

    it "is exposed as a legacy type PJ" do
      is_expected.to include(
        types_de_piece_justificative: [
          {
            "id" => original_pj_id,
            "libelle" => cloned_type_de_champ[:libelle],
            "description" => 'Pour optimiser vos chances, soignez la chorégraphie et privilégiez le chant polyphonique.',
            "lien_demarche" => 'https://www.dance-academy.gouv.fr',
            "order_place" => 0
          }
        ]
      )
    end

    it "is not exposed as a type de champ" do
      expect(subject[:types_de_champ]).to be_empty
    end
  end
end
