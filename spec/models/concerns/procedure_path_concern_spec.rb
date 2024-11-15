# frozen_string_literal: true

describe ProcedurePathConcern do
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

  describe 'path_customized?' do
    let(:procedure) { create :procedure }

    subject { procedure.path_customized? }

    context 'when the path is still the default' do
      it { is_expected.to be_falsey }
    end

    context 'when the path has been changed' do
      before { procedure.claim_path!(procedure.administrateurs.first, 'custom_path') }

      it { expect(procedure.path).to eq('custom_path') }
      it { is_expected.to be_truthy }
    end
  end

  describe '#canonical_path' do
    let!(:procedure) do
      travel_to(3.days.ago) do
        create(:procedure)
      end
    end

    before do
      travel_to(2.days.ago) do
        create(:procedure_path,
          procedure: procedure,
          path: 'older-path')
      end

      travel_to(1.day.ago) do
        create(:procedure_path,
          procedure: procedure,
          path: 'newer-path')
      end

      travel_to(10.days.ago) do
        create(:procedure_path,
          procedure: procedure,
          path: 'other-path')
      end
    end

    it 'returns the path of the most recently updated procedure_path' do
      expect(procedure.canonical_path).to eq('newer-path')
    end
  end
end
