# frozen_string_literal: true

RSpec.describe DossierChampsConcern do
  let(:procedure) { create(:procedure, types_de_champ_public:, types_de_champ_private:) }
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
      subject { dossier.project_champ(type_de_champ_public, row_id:) }

      it { expect(subject.persisted?).to be_truthy }

      context "in repetition" do
        let(:type_de_champ_public) { dossier.find_type_de_champ_by_stable_id(994) }
        let(:row_id) { dossier.project_champ(type_de_champ_repetition).row_ids.first }

        it {
          expect(subject.new_record?).to be_truthy
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
      subject { dossier.project_champ(type_de_champ_private) }

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

    context 'draft user stream' do
      let(:row_id) { nil }
      subject { dossier.with_update_stream(dossier.user).project_champ(type_de_champ_public, row_id:) }

      it { expect(subject.persisted?).to be_truthy }

      context "in repetition" do
        let(:type_de_champ_public) { dossier.find_type_de_champ_by_stable_id(994) }
        let(:row_id) { dossier.project_champ(type_de_champ_repetition).row_ids.first }

        it {
          expect(subject.new_record?).to be_truthy
          expect(subject.row_id).to eq(row_id)
        }
      end

      context "missing champ" do
        before { dossier.champs.where(type: 'Champs::TextChamp').destroy_all; dossier.reload }

        it {
          expect(subject.new_record?).to be_truthy
          expect(subject.is_a?(Champs::TextChamp)).to be_truthy
        }

        context "in repetition" do
          let(:type_de_champ_public) { dossier.find_type_de_champ_by_stable_id(994) }
          let(:row_id) { ULID.generate }

          it {
            expect(subject.new_record?).to be_truthy
            expect(subject.is_a?(Champs::TextChamp)).to be_truthy
            expect(subject.row_id).to eq(row_id)
          }
        end
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
    let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
    subject { dossier.filled_champs_public }

    it { expect(subject.size).to eq(5) }
    it { expect(subject.filter { _1.libelle == 'Nom' }.size).to eq(2) }
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
      before do
        procedure.draft_revision.remove_type_de_champ(type_de_champ_repetition.stable_id)
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
      subject { dossier.champ_for_update(type_de_champ_public, row_id:, updated_by: dossier.user.email) }

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
        let(:project_champ) { dossier.project_champ(type_de_champ_public) }

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
          expect(project_champ.is_a?(Champs::CheckboxChamp)).to be_truthy
        }
      end
    end

    context "private champ" do
      subject { dossier.champ_for_update(type_de_champ_private, row_id:, updated_by: dossier.user.email) }

      it {
        expect(subject.persisted?).to be_truthy
        expect(subject.row_id).to eq(row_id)
      }
    end
  end

  describe "#public_champ_for_update" do
    let(:type_de_champ_repetition) { dossier.find_type_de_champ_by_stable_id(993) }
    let(:row_id) { ULID.generate }

    let(:attributes) do
      {
        "99" => { value: "Hello" },
        "991" => { value: "World" },
        "994-#{row_id}" => { value: "Greer" }
      }
    end

    let(:champ_99) { dossier.project_champ(dossier.find_type_de_champ_by_stable_id(99)) }
    let(:champ_991) { dossier.project_champ(dossier.find_type_de_champ_by_stable_id(991)) }
    let(:champ_994) { dossier.project_champ(dossier.find_type_de_champ_by_stable_id(994), row_id:) }

    def assign_champs_attributes(attributes)
      attributes.each do |public_id, attributes|
        champ = dossier.public_champ_for_update(public_id, updated_by: dossier.user.email)
        champ.assign_attributes(attributes)
      end
    end

    subject { assign_champs_attributes(attributes) }

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
      context 'text -> linked_drop_down_list' do
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
          expect { subject }.to change { dossier.champs.find_by(stable_id: 99).last_write_type_champ }
            .from(TypeDeChamp.type_champs.fetch(:text))
            .to(TypeDeChamp.type_champs.fetch(:linked_drop_down_list))
          expect(champ_99.persisted?).to be_truthy
          expect(champ_99.last_write_type_champ).to eq(TypeDeChamp.type_champs.fetch(:linked_drop_down_list))
          expect(dossier.champs.any?(&:changed_for_autosave?)).to be_truthy
          expect(champ_99.changed?).to be_truthy
          expect(champ_99.value).to eq('["primary",""]')
        }
      end

      context 'textarea -> text' do
        let(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :textarea, libelle: "Un champ textarea", stable_id: 99 }]) }
        let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
        let(:attributes) { { "99" => { value: "test text" } } }

        before do
          tdc = dossier.procedure.draft_revision.find_and_ensure_exclusive_use(99)
          tdc.update!(type_champ: TypeDeChamp.type_champs.fetch(:text))
          dossier.procedure.publish_revision!
          perform_enqueued_jobs
          dossier.reload
        end

        it {
          expect { subject }.to change { dossier.champs.find_by(stable_id: 99).last_write_type_champ }
            .from(TypeDeChamp.type_champs.fetch(:textarea))
            .to(TypeDeChamp.type_champs.fetch(:text))
          expect(champ_99.persisted?).to be_truthy
          expect(champ_99.last_write_type_champ).to eq(TypeDeChamp.type_champs.fetch(:text))
          expect(dossier.champs.any?(&:changed_for_autosave?)).to be_truthy
          expect(champ_99.changed?).to be_truthy
          expect(champ_99.value).to eq('test text')
        }
      end

      context 'yes_no -> checkbox' do
        let(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :yes_no, libelle: "Un champ yes/no", stable_id: 99 }]) }
        let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
        let(:attributes) { { "99" => { value: "true" } } }

        before do
          tdc = dossier.procedure.draft_revision.find_and_ensure_exclusive_use(99)
          tdc.update!(type_champ: TypeDeChamp.type_champs.fetch(:checkbox))
          dossier.procedure.publish_revision!
          perform_enqueued_jobs
          dossier.reload
        end

        it {
          expect { subject }.to change { dossier.champs.find_by(stable_id: 99).last_write_type_champ }
            .from(TypeDeChamp.type_champs.fetch(:yes_no))
            .to(TypeDeChamp.type_champs.fetch(:checkbox))
          expect(champ_99.persisted?).to be_truthy
          expect(champ_99.last_write_type_champ).to eq(TypeDeChamp.type_champs.fetch(:checkbox))
          expect(dossier.champs.any?(&:changed_for_autosave?)).to be_truthy
          expect(champ_99.changed?).to be_truthy
          expect(champ_99.value).to eq('true')
        }
      end

      context 'regions -> text' do
        let(:procedure) { create(:procedure, :published, types_de_champ_public: [{ type: :regions, libelle: "Un champ regions", stable_id: 99 }]) }
        let(:dossier) { create(:dossier, :with_populated_champs, procedure:) }
        let(:attributes) { { "99" => { value: "test text" } } }

        before do
          tdc = dossier.procedure.draft_revision.find_and_ensure_exclusive_use(99)
          tdc.update!(type_champ: TypeDeChamp.type_champs.fetch(:text))
          dossier.procedure.publish_revision!
          perform_enqueued_jobs
          dossier.reload
        end

        it {
          expect { subject }.to change { dossier.champs.find_by(stable_id: 99).last_write_type_champ }
            .from(TypeDeChamp.type_champs.fetch(:regions))
            .to(TypeDeChamp.type_champs.fetch(:text))
          expect(champ_99.persisted?).to be_truthy
          expect(champ_99.last_write_type_champ).to eq(TypeDeChamp.type_champs.fetch(:text))
          expect(dossier.champs.any?(&:changed_for_autosave?)).to be_truthy
          expect(champ_99.changed?).to be_truthy
          expect(champ_99.value).to eq('test text')
        }
      end
    end
  end

  describe "#private_champ_for_update" do
    let(:attributes) do
      {
        "995" => { value: "Hello" }
      }
    end

    let(:annotation_995) { dossier.project_champ(dossier.find_type_de_champ_by_stable_id(995)) }

    def assign_champs_attributes(attributes)
      attributes.each do |public_id, attributes|
        champ = dossier.private_champ_for_update(public_id, updated_by: dossier.user.email)
        champ.assign_attributes(attributes)
      end
    end

    subject { assign_champs_attributes(attributes) }

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

  context 'en_construction(user)' do
    let(:dossier) { create(:dossier, :en_construction, procedure:) }

    describe "#public_champ_for_update" do
      before { Flipper.enable(:user_buffer_stream, procedure) }

      let(:type_de_champ_repetition) { dossier.find_type_de_champ_by_stable_id(993) }
      let(:row_ids) { dossier.project_champ(type_de_champ_repetition).row_ids }
      let(:row_id) { row_ids.first }

      let(:attributes) do
        {
          "99" => { value: "Hello" },
          "991" => { value: "World" },
          "994-#{row_id}" => { value: "Greer" }
        }
      end

      let(:new_attributes) do
        {
          "99" => { value: "Hello!!!" },
          "994-#{row_id}" => { value: "Greer is the best" }
        }
      end

      let(:bad_attributes) do
        {
          "99" => { value: "bad" },
          "994-#{row_id}" => { value: "bad" }
        }
      end

      def main_champ(stable_id, row_id = nil)
        dossier.with_main_stream do
          dossier.project_champ(dossier.find_type_de_champ_by_stable_id(stable_id), row_id:)
        end
      end

      def draft_champ(stable_id, row_id = nil)
        dossier.with_update_stream(dossier.user) do
          dossier.project_champ(dossier.find_type_de_champ_by_stable_id(stable_id), row_id:)
        end
      end

      def main_champ_99 = main_champ(99)
      def main_champ_991 = main_champ(991)
      def main_champ_994 = main_champ(994, row_id)
      def draft_champ_99 = draft_champ(99)
      def draft_champ_991 = draft_champ(991)
      def draft_champ_994 = draft_champ(994, row_id)

      def assign_champs_attributes(attributes)
        attributes.each do |public_id, attributes|
          champ = dossier.public_champ_for_update(public_id, updated_by: dossier.user.email)
          champ.assign_attributes(attributes)
        end
      end

      subject do
        dossier.with_update_stream(dossier.user) { assign_champs_attributes(attributes) }
      end

      it {
        subject
        dossier.save!

        expect(dossier.user_buffer_changes?).to be_truthy

        expect(main_champ_99.stream).to eq(Champ::MAIN_STREAM)
        expect(main_champ_991.stream).to eq(Champ::MAIN_STREAM)
        expect(main_champ_994.stream).to eq(Champ::MAIN_STREAM)

        expect(main_champ_99.value).to be_nil
        expect(main_champ_991.value).to be_nil
        expect(main_champ_994.value).to be_nil

        expect(draft_champ_99.stream).to eq(Champ::USER_BUFFER_STREAM)
        expect(draft_champ_991.stream).to eq(Champ::USER_BUFFER_STREAM)
        expect(draft_champ_994.stream).to eq(Champ::USER_BUFFER_STREAM)

        expect(draft_champ_99.value).to eq("Hello")
        expect(draft_champ_991.value).to eq("World")
        expect(draft_champ_994.value).to eq("Greer")
        expect(dossier.history.size).to eq(0)

        dossier.merge_user_buffer_stream!

        expect(main_champ_99.value).to eq("Hello")
        expect(main_champ_991.value).to eq("World")
        expect(main_champ_994.value).to eq("Greer")
        expect(dossier.history.size).to eq(2)

        travel_to(1.hour.from_now) do
          dossier.with_update_stream(dossier.user) { assign_champs_attributes(new_attributes) }
          dossier.save!
          dossier.merge_user_buffer_stream!
        end

        expect(main_champ_99.value).to eq("Hello!!!")
        expect(main_champ_994.value).to eq("Greer is the best")
        expect(dossier.history.size).to eq(4)

        travel_to(2.hours.from_now) do
          dossier.with_update_stream(dossier.user) { assign_champs_attributes(bad_attributes) }
          dossier.save!
        end

        expect(draft_champ_99.value).to eq("bad")
        expect(draft_champ_991.value).to eq("World")
        expect(draft_champ_994.value).to eq("bad")
        dossier.reset_user_buffer_stream!
        expect(draft_champ_99.value).to eq("Hello!!!")
        expect(draft_champ_991.value).to eq("World")
        expect(draft_champ_994.value).to eq("Greer is the best")
      }

      context "missing champs" do
        before { dossier; Champs::TextChamp.destroy_all; dossier.champs.reload }

        it {
          subject
          dossier.save!

          expect(draft_champ_99.stream).to eq(Champ::USER_BUFFER_STREAM)
          expect(draft_champ_991.stream).to eq(Champ::USER_BUFFER_STREAM)
          expect(draft_champ_994.stream).to eq(Champ::USER_BUFFER_STREAM)

          expect(draft_champ_99.value).to eq("Hello")
          expect(draft_champ_991.value).to eq("World")
          expect(draft_champ_994.value).to eq("Greer")

          expect(dossier.history.size).to eq(0)
          dossier.merge_user_buffer_stream!
          expect(dossier.history.size).to eq(0)
        }
      end
    end
  end
end
