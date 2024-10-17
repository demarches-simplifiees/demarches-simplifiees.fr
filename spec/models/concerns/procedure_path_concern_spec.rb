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
        procedure.procedure_paths.create(path: 'path1')
      end
    end

    let!(:procedure_path2) do
      travel_to(1.day.ago) do
        procedure.procedure_paths.create(path: 'path2')
      end
    end

    it 'returns the path of the earliest created procedure_path' do
      expect(procedure.canonical_path).to eq('path2')
    end

    context 'when the procedure set path1 as main path again' do
      before { procedure.update(path: 'path1') }

      it 'returns the path of the earliest created procedure_path' do
        expect(procedure.canonical_path).to eq('path1')
      end
    end
  end

  describe "#destroy" do
    let!(:procedure) { create(:procedure) }

    context 'when there is only one procedure_path (the uuid)' do
      it do
        procedure_path = procedure.procedure_paths.first
        expect { procedure_path.destroy }.not_to change { procedure.procedure_paths.count }
        expect { procedure_path.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
      end
    end

    context "when there is more than one procedure_path" do
      let!(:procedure_path1) { procedure.procedure_paths.create(path: 'path1') }

      it { expect { procedure_path1.destroy }.to change { procedure.procedure_paths.count }.from(2).to(1) }
    end
  end

  describe "#add_procedure_path" do
    let(:procedure) { build(:procedure, :published) }

    subject { procedure.save! }

    it 'sets the procedure path' do
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

      it "should not let procedure1 change path to procedure2 path" do
        expect { procedure1.update!(path: procedure2.path) }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
