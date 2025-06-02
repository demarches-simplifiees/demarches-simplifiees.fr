# frozen_string_literal: true

RSpec.describe DossierChampsConcern do
  let(:procedure) do
    create(:procedure, types_de_champ_public:, types_de_champ_private:)
  end
  let(:types_de_champ_public) do
    [
      { type: :text, libelle: "Un champ text", stable_id: 99 },
      { type: :text, libelle: "Un autre champ text", stable_id: 991 },
      { type: :yes_no, libelle: "Un champ yes no", stable_id: 992 },
      { type: :repetition, libelle: "Un champ répétable", stable_id: 993, mandatory: true, children: [{ type: :text, libelle: 'Nom', stable_id: 994 }] }
    ]
  end
  let(:types_de_champ_private) do
    [
      { type: :text, libelle: "Une annotation", stable_id: 995 }
    ]
  end
  let(:dossier) { create(:dossier, procedure:) }

  describe "#find_type_de_champ_by_stable_id(public)" do
    subject { dossier.find_type_de_champ_by_stable_id(992, :public) }

    it { is_expected.to be_truthy }
  end

  describe "#find_type_de_champ_by_stable_id(private)" do
    subject { dossier.find_type_de_champ_by_stable_id(995, :private) }

    it { is_expected.to be_truthy }
  end

  describe "#project_champ" do
    let(:type_de_champ_repetition) { dossier.find_type_de_champ_by_stable_id(993) }
    let(:type_de_champ_public) { dossier.find_type_de_champ_by_stable_id(99) }
    let(:type_de_champ_private) { dossier.find_type_de_champ_by_stable_id(995) }
    let(:row_ids) { dossier.project_champ(type_de_champ_repetition, nil).row_ids }

    context "public champ" do
      let(:row_id) { nil }
      subject { dossier.project_champ(type_de_champ_public, row_id) }

      it { expect(subject.persisted?).to be_truthy }

      context "in repetition" do
        let(:type_de_champ_public) { dossier.find_type_de_champ_by_stable_id(994) }
        let(:row_id) { row_ids.first }

        it {
          expect(subject.persisted?).to be_truthy
          expect(subject.row_id).to eq(row_id)
          expect(subject.parent_id).not_to be_nil
        }
      end

      context "missing champ" do
        before { dossier; Champs::TextChamp.destroy_all }

        it {
          expect(subject.new_record?).to be_truthy
          expect(subject.is_a?(Champs::TextChamp)).to be_truthy
        }

        context "in repetition" do
          let(:type_de_champ_public) { dossier.find_type_de_champ_by_stable_id(994) }
          let(:row_id) { row_ids.first }

          it {
            expect(subject.new_record?).to be_truthy
            expect(subject.is_a?(Champs::TextChamp)).to be_truthy
            expect(subject.row_id).to eq(row_id)
          }
        end
      end
    end

    context "private champ" do
      subject { dossier.project_champ(type_de_champ_private, nil) }

      it { expect(subject.persisted?).to be_truthy }

      context "missing champ" do
        before { dossier; Champs::TextChamp.destroy_all }

        it {
          expect(subject.new_record?).to be_truthy
          expect(subject.is_a?(Champs::TextChamp)).to be_truthy
        }
      end
    end
  end

  describe "#champs_for_export" do
    subject { dossier.champs_for_export(dossier.revision.types_de_champ_public) }

    it { expect(subject.size).to eq(4) }
    it { expect(subject.first).to eq(["Un champ text", nil]) }
  end

  describe "#champs_for_prefill" do
    subject { dossier.champs_for_prefill([991, 995]) }

    it {
      expect(subject.size).to eq(2)
      expect(subject.map(&:libelle)).to eq(["Une annotation", "Un autre champ text"])
      expect(subject.all?(&:persisted?)).to be_truthy
    }

    context "missing champ" do
      before { dossier; Champs::TextChamp.destroy_all }

      it {
        expect(subject.size).to eq(2)
        expect(subject.map(&:libelle)).to eq(["Une annotation", "Un autre champ text"])
        expect(subject.all?(&:persisted?)).to be_truthy
      }
    end
  end

  describe "#champ_for_update" do
    let(:type_de_champ_repetition) { dossier.find_type_de_champ_by_stable_id(993) }
    let(:type_de_champ_public) { dossier.find_type_de_champ_by_stable_id(99) }
    let(:type_de_champ_private) { dossier.find_type_de_champ_by_stable_id(995) }
    let(:row_ids) { dossier.project_champ(type_de_champ_repetition, nil).row_ids }
    let(:row_id) { nil }

    context "public champ" do
      subject { dossier.champ_for_update(type_de_champ_public, row_id, updated_by: dossier.user.email) }

      it {
        expect(subject.persisted?).to be_truthy
        expect(subject.row_id).to eq(row_id)
      }

      context "in repetition" do
        let(:type_de_champ_public) { dossier.find_type_de_champ_by_stable_id(994) }
        let(:row_id) { row_ids.first }

        it {
          expect(subject.persisted?).to be_truthy
          expect(subject.row_id).to eq(row_id)
          expect(subject.parent_id).not_to be_nil
        }
      end

      context "missing champ" do
        before { dossier; Champs::TextChamp.destroy_all }

        it {
          expect(subject.persisted?).to be_truthy
          expect(subject.is_a?(Champs::TextChamp)).to be_truthy
        }

        context "in repetition" do
          let(:type_de_champ_public) { dossier.find_type_de_champ_by_stable_id(994) }
          let(:row_id) { row_ids.first }

          it {
            expect(subject.persisted?).to be_truthy
            expect(subject.is_a?(Champs::TextChamp)).to be_truthy
            expect(subject.row_id).to eq(row_id)
            expect(subject.parent_id).not_to be_nil
          }
        end
      end
    end

    context "private champ" do
      subject { dossier.champ_for_update(type_de_champ_private, row_id, updated_by: dossier.user.email) }

      it {
        expect(subject.persisted?).to be_truthy
        expect(subject.row_id).to eq(row_id)
      }
    end
  end

  describe "#update_champs_attributes(public)" do
    let(:type_de_champ_repetition) { dossier.find_type_de_champ_by_stable_id(993) }
    let(:row_ids) { dossier.project_champ(type_de_champ_repetition, nil).row_ids }
    let(:row_id) { row_ids.first }

    let(:attributes) do
      {
        "99" => { value: "Hello" },
        "991" => { value: "World" },
        "994-#{row_id}" => { value: "Greer" }
      }
    end

    let(:champ_99) { dossier.project_champ(dossier.find_type_de_champ_by_stable_id(99), nil) }
    let(:champ_991) { dossier.project_champ(dossier.find_type_de_champ_by_stable_id(991), nil) }
    let(:champ_994) { dossier.project_champ(dossier.find_type_de_champ_by_stable_id(994), row_id) }

    subject { dossier.update_champs_attributes(attributes, :public, updated_by: dossier.user.email) }

    it {
      subject
      expect(dossier.champs.any?(&:changed_for_autosave?)).to be_truthy
      expect(champ_99.changed?).to be_truthy
      expect(champ_991.changed?).to be_truthy
      expect(champ_994.changed?).to be_truthy
      expect(champ_99.value).to eq("Hello")
      expect(champ_991.value).to eq("World")
      expect(champ_994.value).to eq("Greer")
    }

    context "missing champs" do
      before { dossier; Champs::TextChamp.destroy_all; }

      it {
        subject
        expect(dossier.champs.any?(&:changed_for_autosave?)).to be_truthy
        expect(champ_99.changed?).to be_truthy
        expect(champ_991.changed?).to be_truthy
        expect(champ_994.changed?).to be_truthy
        expect(champ_99.value).to eq("Hello")
        expect(champ_991.value).to eq("World")
        expect(champ_994.value).to eq("Greer")
      }
    end
  end

  describe "#update_champs_attributes(private)" do
    let(:attributes) do
      {
        "995" => { value: "Hello" }
      }
    end

    let(:annotation_995) { dossier.project_champ(dossier.find_type_de_champ_by_stable_id(995), nil) }

    subject { dossier.update_champs_attributes(attributes, :private, updated_by: dossier.user.email) }

    it {
      subject
      expect(dossier.champs.any?(&:changed_for_autosave?)).to be_truthy
      expect(annotation_995.changed?).to be_truthy
      expect(annotation_995.value).to eq("Hello")
    }

    context "missing champs" do
      before { dossier; Champs::TextChamp.destroy_all; }

      it {
        subject
        expect(dossier.champs.any?(&:changed_for_autosave?)).to be_truthy
        expect(annotation_995.changed?).to be_truthy
        expect(annotation_995.value).to eq("Hello")
      }
    end
  end
end
