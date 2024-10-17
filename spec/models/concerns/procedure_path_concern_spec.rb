# frozen_string_literal: true

describe ProcedurePathConcern do
  describe ".procedure_paths cannot be empty" do
    let(:procedure) { build(:procedure, procedure_paths: []) }

    it { expect(procedure.valid?).to be_falsey }
  end

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
  end
end
