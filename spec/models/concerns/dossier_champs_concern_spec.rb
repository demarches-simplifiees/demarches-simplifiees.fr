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

    context "public champ" do
      let(:row_id) { nil }
      subject { dossier.project_champ(type_de_champ_public, row_id) }

      it { expect(subject.persisted?).to be_truthy }

      context "in repetition" do
        let(:type_de_champ_public) { dossier.find_type_de_champ_by_stable_id(994) }
        let(:row_id) { dossier.project_champ(type_de_champ_repetition, nil).row_ids.first }

        it {
          expect(subject.persisted?).to be_truthy
          expect(subject.row_id).to eq(row_id)
        }

        context "invalid row_id" do
          let(:type_de_champ_public) { dossier.find_type_de_champ_by_stable_id(99) }
          it {
            expect { subject }.to raise_error("type_de_champ #{type_de_champ_public.stable_id} in revision #{dossier.revision_id} can not have a row_id because it is not part of a repetition")
          }
        end
      end

      context "missing champ" do
        before { dossier.champs.where(type: 'Champs::TextChamp').destroy_all; dossier.reload }

        it {
          expect(subject.new_record?).to be_truthy
          expect(subject.is_a?(Champs::TextChamp)).to be_truthy
          expect(subject.updated_at).not_to be_nil
        }

        context "in repetition" do
          let(:type_de_champ_public) { dossier.find_type_de_champ_by_stable_id(994) }
          let(:row_id) { ULID.generate }

          it {
            expect(subject.new_record?).to be_truthy
            expect(subject.is_a?(Champs::TextChamp)).to be_truthy
            expect(subject.row_id).to eq(row_id)
            expect(subject.updated_at).not_to be_nil
          }

          context "invalid row_id" do
            let(:type_de_champ_public) { dossier.find_type_de_champ_by_stable_id(99) }
            it {
              expect { subject }.to raise_error("type_de_champ #{type_de_champ_public.stable_id} in revision #{dossier.revision_id} can not have a row_id because it is not part of a repetition")
            }
          end
        end
      end
    end

    context "private champ" do
      subject { dossier.project_champ(type_de_champ_private, nil) }

      it { expect(subject.persisted?).to be_truthy }

      context "missing champ" do
        before { dossier.champs.where(type: 'Champs::TextChamp').destroy_all; dossier.reload }

        it {
          expect(subject.new_record?).to be_truthy
          expect(subject.is_a?(Champs::TextChamp)).to be_truthy
          expect(subject.updated_at).not_to be_nil
        }
      end
    end
  end

  describe '#project_champs_public' do
    subject { dossier.project_champs_public }

    it { expect(subject.size).to eq(4) }
    it { expect(subject.find { _1.libelle == 'Nom' }).to be_falsey }
  end

  describe '#project_champs_private' do
    subject { dossier.project_champs_private }

    it { expect(subject.size).to eq(1) }
  end

  describe '#filled_champs_public' do
    let(:types_de_champ_public) do
      [
        { type: :header_section },
        { type: :text, libelle: "Un champ text" },
        { type: :text, libelle: "Un autre champ text" },
        { type: :yes_no, libelle: "Un champ yes no" },
        { type: :repetition, libelle: "Un champ répétable", mandatory: true, children: [{ type: :text, libelle: 'Nom' }] },
        { type: :explication }
      ]
    end
    subject { dossier.filled_champs_public }

    it { expect(subject.size).to eq(4) }
    it { expect(subject.find { _1.libelle == 'Nom' }).to be_truthy }
  end

  describe '#filled_champs_private' do
    let(:types_de_champ_private) do
      [
        { type: :header_section },
        { type: :text, libelle: "Une annotation" },
        { type: :explication }
      ]
    end
    subject { dossier.filled_champs_private }

    it { expect(subject.size).to eq(1) }
  end

  describe '#repetition_row_ids' do
    let(:type_de_champ_repetition) { dossier.find_type_de_champ_by_stable_id(993) }
    subject { dossier.repetition_row_ids(type_de_champ_repetition) }

    it { expect(subject.size).to eq(1) }

    context 'given a type de champ repetition in another revision' do
      let(:procedure) { create(:procedure, :published, types_de_champ_public:, types_de_champ_private:) }
      let(:draft) { procedure.draft_revision }
      let(:errored_stable_id) { 666 }
      let(:type_de_champ_repetition) { procedure.active_revision.types_de_champ.find { _1.stable_id == errored_stable_id } }
      before do
        dossier
        tdc_repetition = draft.add_type_de_champ(type_champ: :repetition, libelle: "repetition", stable_id: errored_stable_id)
        draft.add_type_de_champ(type_champ: :text, libelle: "t1", parent_stable_id: tdc_repetition.stable_id)
        procedure.publish_revision!
      end

      it { expect { subject }.not_to raise_error }
    end
  end

  describe '#project_rows_for' do
    let(:type_de_champ_repetition) { dossier.find_type_de_champ_by_stable_id(993) }
    subject { dossier.project_rows_for(type_de_champ_repetition) }

    it { expect(subject.size).to eq(1) }
    it { expect(subject.first.size).to eq(1) }
  end

  describe '#repetition_add_row' do
    let(:type_de_champ_repetition) { dossier.find_type_de_champ_by_stable_id(993) }
    let(:row_ids) { dossier.repetition_row_ids(type_de_champ_repetition) }
    subject { dossier.repetition_add_row(type_de_champ_repetition, updated_by: 'test') }

    it { expect { subject }.to change { dossier.repetition_row_ids(type_de_champ_repetition).size }.by(1) }
    it { expect(subject).to be_in(row_ids) }
  end

  describe '#repetition_remove_row' do
    let(:type_de_champ_repetition) { dossier.find_type_de_champ_by_stable_id(993) }
    let(:row_id) { dossier.repetition_row_ids(type_de_champ_repetition).first }
    let(:row_ids) { dossier.repetition_row_ids(type_de_champ_repetition) }
    subject { dossier.repetition_remove_row(type_de_champ_repetition, row_id, updated_by: 'test') }

    it { expect { subject }.to change { dossier.repetition_row_ids(type_de_champ_repetition).size }.by(-1) }
    it { row_id; subject; expect(row_id).not_to be_in(row_ids) }
  end

  describe "#champ_values_for_export" do
    subject { dossier.champ_values_for_export(dossier.revision.types_de_champ_public, format: :xlsx) }

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
    let(:row_id) { nil }

    context "public champ" do
      subject { dossier.champ_for_update(type_de_champ_public, row_id, updated_by: dossier.user.email) }

      it {
        expect(subject.persisted?).to be_truthy
        expect(subject.row_id).to eq(row_id)
      }

      context "in repetition" do
        let(:type_de_champ_public) { dossier.find_type_de_champ_by_stable_id(994) }
        let(:row_id) { ULID.generate }

        it {
          expect(subject.persisted?).to be_truthy
          expect(subject.row_id).to eq(row_id)
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
          let(:row_id) { ULID.generate }

          it {
            expect(subject.persisted?).to be_truthy
            expect(subject.is_a?(Champs::TextChamp)).to be_truthy
            expect(subject.row_id).to eq(row_id)
          }
        end
      end

      context "champ with type change" do
        let(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :text, libelle: "Un champ text", stable_id: 99 }]) }
        let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }

        before do
          tdc = dossier.procedure.draft_revision.find_and_ensure_exclusive_use(99)
          tdc.update!(type_champ: TypeDeChamp.type_champs.fetch(:checkbox))
          dossier.procedure.publish_revision!
          perform_enqueued_jobs
          dossier.reload
        end

        it {
          expect(subject.persisted?).to be_truthy
          expect(subject.is_a?(Champs::CheckboxChamp)).to be_truthy
          expect(subject.value).to be_nil
        }
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
    let(:row_id) { ULID.generate }

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

    context "champ with type change" do
      let(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :text, libelle: "Un champ text", stable_id: 99 }]) }
      let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
      let(:attributes) { { "99" => { primary_value: "primary" } } }

      before do
        tdc = dossier.procedure.draft_revision.find_and_ensure_exclusive_use(99)
        tdc.update!(type_champ: TypeDeChamp.type_champs.fetch(:linked_drop_down_list), drop_down_options: ["--primary--", "secondary"])
        dossier.procedure.publish_revision!
        perform_enqueued_jobs
        dossier.reload
      end

      it {
        subject
        expect(dossier.champs.any?(&:changed_for_autosave?)).to be_truthy
        expect(champ_99.changed?).to be_truthy
        expect(champ_99.value).to eq('["primary",""]')
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
