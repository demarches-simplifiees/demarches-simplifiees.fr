# frozen_string_literal: true

RSpec.describe ProcedurePath, type: :model do
  describe '#uuid_path?' do
    it 'returns true for valid UUID format paths' do
      procedure_path = build(:procedure_path, path: '123e4567-e89b-12d3-a456-426614174000')
      expect(procedure_path.uuid_path?).to be true
    end

    it 'returns false for non-UUID format paths' do
      [
        'ma-super-demarche',
        'demarch-2024',
      ].each do |path|
        procedure_path = build(:procedure_path, path: path)
        expect(procedure_path.uuid_path?).to be false
      end
    end
  end

  describe '#destroy' do
    let(:procedure) { create(:procedure) }

    context 'when it is the only path' do
      it 'prevents destruction' do
        expect { procedure.procedure_paths.first.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
        expect { procedure.procedure_paths.first.destroy }.not_to change(ProcedurePath, :count).from(1)
      end
    end

    context 'when there are multiple paths' do
      let!(:procedure_path1) { create(:procedure_path, procedure: procedure) }

      it 'allows destruction' do
        expect { procedure_path1.destroy }.to change(ProcedurePath, :count).from(2).to(1)
      end
    end

    context 'when path is a UUID' do
      let(:procedure_path) { create(:procedure_path, procedure: procedure, path: '123e4567-e89b-12d3-a456-426614174000') }

      it 'prevents destruction' do
        expect { procedure_path.destroy! }.to raise_error(ActiveRecord::RecordNotDestroyed)
        expect { procedure_path.destroy }.not_to change(ProcedurePath, :count)
      end
    end

    context 'when destroyed by association' do
      let!(:procedure_path) { create(:procedure_path, procedure: procedure, path: '123e4567-e89b-12d3-a456-426614174000') }

      it 'allows destruction' do
        expect { procedure.destroy }.to change(ProcedurePath, :count).from(2).to(0)
      end
    end
  end
end
