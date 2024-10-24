# frozen_string_literal: true

RSpec.describe DossierEmptyConcern do
  describe 'empty_brouillon' do
    let(:types) { [{ type: :text }, { type: :carte }, { type: :piece_justificative }] }
    let(:procedure) { create(:procedure, types_de_champ_public: types) }
    let!(:empty_brouillon) { create(:dossier, procedure:) }
    let!(:empty_en_construction) { create(:dossier, :en_construction, procedure:) }
    let!(:value_filled_dossier) { create(:dossier, procedure:) }
    let!(:carte_filled_dossier) { create(:dossier, procedure:) }
    let!(:pj_filled_dossier) { create(:dossier, procedure:) }
    let(:geo_area) { build(:geo_area, :selection_utilisateur, :polygon) }
    let(:attachment) { { io: StringIO.new("toto"), filename: "toto.png", content_type: "image/png" } }

    subject { Dossier.empty_brouillon(2.days.ago..) }

    before do
      value_filled_dossier.champs.first.update(value: 'filled')
      carte_filled_dossier.champs.second.update(geo_areas: [geo_area])
      pj_filled_dossier.champs.third.piece_justificative_file.attach(attachment)
    end

    it do
      is_expected.to eq([empty_brouillon])
    end
  end
end
