# frozen_string_literal: true

describe ProcedurePathConcern do
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
