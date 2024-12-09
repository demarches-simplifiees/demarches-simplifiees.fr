# frozen_string_literal: true

describe DossierSectionsConcern do
  describe '#auto_numbering_section_headers_for?' do
    let(:public_libelle) { "Infos" }
    let(:private_libelle) { "Infos Private" }
    let(:types_de_champ_public) { [{ type: :header_section, libelle: public_libelle }, { type: :header_section, libelle: "Details" }] }
    let(:types_de_champ_private) { [{ type: :header_section, libelle: private_libelle }, { type: :header_section, libelle: "Details Private" }] }

    let(:procedure) { create(:procedure, :for_individual, types_de_champ_public:, types_de_champ_private:) }
    let(:dossier) { create(:dossier, procedure: procedure) }

    let(:public_type_de_champ) { dossier.types_de_champ_public[1] }
    let(:private_type_de_champ) { dossier.types_de_champ_private[1] }

    context "with no section having number" do
      it { expect(dossier.auto_numbering_section_headers_for?(public_type_de_champ)).to eq(true) }
      it { expect(dossier.auto_numbering_section_headers_for?(private_type_de_champ)).to eq(true) }
    end

    context "with public section having number" do
      let(:public_libelle) { "1 - infos" }
      it { expect(dossier.auto_numbering_section_headers_for?(public_type_de_champ)).to eq(false) }
      it { expect(dossier.auto_numbering_section_headers_for?(private_type_de_champ)).to eq(true) }
    end

    context "with private section having number" do
      let(:private_libelle) { "1 - infos private" }
      it { expect(dossier.auto_numbering_section_headers_for?(public_type_de_champ)).to eq(true) }
      it { expect(dossier.auto_numbering_section_headers_for?(private_type_de_champ)).to eq(false) }
    end

    context "header_section in a repetition are not auto-numbered" do
      let(:types_de_champ_public) { [{ type: :header_section, libelle: public_libelle }, { type: :repetition, mandatory: true, children: [{ type: :header_section, libelle: "Enfant" }, { type: :text }] }] }

      let(:public_type_de_champ) { dossier.revision.children_of(dossier.types_de_champ_public[1]).first }

      context "with parent section having headers with number" do
        let(:public_libelle) { "1. Infos" }
        it { expect(dossier.auto_numbering_section_headers_for?(public_type_de_champ)).to eq(false) }
      end

      context "with parent section having headers without number" do
        let(:public_libelle) { "infos" }
        it { expect(dossier.auto_numbering_section_headers_for?(public_type_de_champ)).to eq(false) }
      end
    end
  end

  describe '#index_for_section_header' do
    include Logic
    let(:number_stable_id) { 99 }
    let(:types_de_champ) do
      [
        { type: :header_section, libelle: "Infos" }, { type: :integer_number, stable_id: number_stable_id },
        { type: :header_section, libelle: "Details", condition: ds_eq(champ_value(99), constant(5)) }, { type: :header_section, libelle: "Conclusion" }
      ]
    end

    let(:procedure) { create(:procedure, :for_individual, types_de_champ_public: types_de_champ) }
    let(:dossier) { create(:dossier, procedure: procedure) }

    let(:headers) { dossier.revision.types_de_champ_public.filter(&:header_section?) }

    let(:number_value) { nil }

    before do
      dossier.champs.find { _1.stable_id == number_stable_id }.update(value: number_value)
      dossier.reload
    end

    context "when there are invisible sections" do
      it "index accordingly header sections" do
         expect(dossier.index_for_section_header(headers[0])).to eq(1)
         expect(dossier.project_champ(headers[1])).not_to be_visible
         expect(dossier.index_for_section_header(headers[2])).to eq(2)
       end
    end

    context "when all headers are visible" do
      let(:number_value) { 5 }
      it "index accordingly header sections" do
        expect(dossier.index_for_section_header(headers[0])).to eq(1)
        expect(dossier.project_champ(headers[1])).to be_visible
        expect(dossier.index_for_section_header(headers[1])).to eq(2)
        expect(dossier.index_for_section_header(headers[2])).to eq(3)
      end
    end
  end
end
