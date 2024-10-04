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
        'demarch-2024'
      ].each do |path|
        procedure_path = build(:procedure_path, path: path)
        expect(procedure_path.uuid_path?).to be false
      end
    end
  end
end
