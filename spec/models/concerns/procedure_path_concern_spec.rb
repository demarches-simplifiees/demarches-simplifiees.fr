# frozen_string_literal: true

describe ProcedurePathConcern do
  describe "#canonical_path" do
    let!(:procedure) do
      travel_to(3.days.ago) do
        create(:procedure)
      end
    end

    let!(:procedure_path1) do
      travel_to(2.days.ago) do
        procedure.procedure_paths.create(path: "path1")
      end
    end

    let!(:procedure_path2) do
      travel_to(1.day.ago) do
        procedure.procedure_paths.create(path: "path2")
      end
    end

    it "returns the path of the earliest created procedure_path" do
      expect(procedure.canonical_path).to eq("path2")
    end

    context "when the procedure set path1 as main path again" do
      before { procedure.update(path: "path1") }

      it "returns the path of the earliest created procedure_path" do
        expect(procedure.canonical_path).to eq("path1")
      end
    end
  end

  describe "#destroy" do
    let!(:procedure) { create(:procedure) }

    context "when there is only one procedure_path (the uuid)" do
      it do
        procedure_path = procedure.procedure_paths.first
        expect { procedure_path.destroy }.not_to change { procedure.procedure_paths.count }
        expect { procedure_path.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
      end
    end

    context "when there is more than one procedure_path" do
      let!(:procedure_path1) { procedure.procedure_paths.create(path: "path1") }

      it { expect { procedure_path1.destroy }.to change { procedure.procedure_paths.count }.from(2).to(1) }
    end
  end

  describe "#sync_procedure_path" do
    let(:procedure) { build(:procedure, :published) }

    subject { procedure.save! }

    it "sets the procedure path" do
      expect { subject }.to change { procedure.procedure_paths.count }.from(0).to(1)
    end

    context "when the procedure path change" do
      let(:procedure) { create(:procedure, path: "old-path") }

      before do
        procedure.path = "new-path"
      end

      it "keep old path" do
        expect { subject }.to change { procedure.procedure_paths.count }.from(1).to(2)
        expect(procedure.procedure_paths.reload.by_updated_at.pluck(:path)).to eq(["new-path", "old-path"])
      end
    end

    context "when there is 2 procedures" do
      let(:procedure1) { create(:procedure, :published, administrateurs: [create(:administrateur)], path: "proc-1") }
      let(:procedure2) { create(:procedure, :published, administrateurs: [create(:administrateur)], path: "proc-2") }

      it "should have 2 diff paths" do
        expect(procedure1.path).not_to eq(procedure2.path)
      end

      it "should let procedure1 change path to procedure2 path" do
        expect { procedure1.update!(path: procedure2.path) }.not_to raise_error
        expect(procedure1.path).to eq("proc-2")
      end
    end
  end

  describe ".find_with_path" do
    let!(:procedure1) { create(:procedure) }

    let!(:procedure_path1) { procedure1.procedure_paths.create(path: "test-path-1") }

    context "when a procedure with the given path exists" do
      it "returns the procedure with the matching path" do
        result = Procedure.find_with_path("test-path-1").first

        expect(result).to eq(procedure1)
      end
    end

    context "when no procedure with the given path exists" do
      it "returns an empty result" do
        result = Procedure.find_with_path("unknown-path").first

        expect(result).to be_nil
      end
    end
  end

  describe "#claim_path!" do
    let!(:procedure) { create(:procedure) }
    let!(:procedure_2) { create(:procedure) }
    let!(:procedure_path) { create(:procedure_path, procedure: procedure, path: "test-path") }
    let!(:procedure_path_2) { create(:procedure_path, procedure: procedure_2, path: "test-path-2") }
    let(:administrateur) { procedure.administrateurs.first }

    it "assigns the procedure to the procedure_path" do
      expect { procedure.claim_path!(administrateur, procedure_path_2.path) }.to change { procedure_path_2.reload.procedure }.from(procedure_2).to(procedure)
    end
  end

  describe '#canonical_path' do
    let!(:procedure) do
      travel_to(3.days.ago) do
        create(:procedure)
      end
    end

    it 'returns the path of the most recently updated procedure_path' do
      # Create procedure paths with different timestamps
      create(:procedure_path,
        procedure: procedure,
        path: 'older-path',
        updated_at: 2.days.ago)
      create(:procedure_path,
        procedure: procedure,
        path: 'newer-path',
        updated_at: 1.day.ago)

      expect(procedure.canonical_path).to eq('newer-path')
    end
  end
end
