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
end
