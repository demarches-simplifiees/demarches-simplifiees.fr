require 'spec_helper'

describe ProcedurePath do
  describe 'assocations' do
    it { is_expected.to belong_to(:administrateur) }
    it { is_expected.to belong_to(:procedure) }
  end

  describe 'attributes' do
    it { is_expected.to have_db_column(:path) }
  end

  describe 'validation' do
    describe 'path' do
      let(:admin) { create(:administrateur) }
      let(:procedure) { create(:procedure) }
      let(:procedure_path) { create(:procedure_path, administrateur: admin, procedure: procedure, path: path) }

      context 'when path is nil' do
        let(:path) { nil }
        it { expect{procedure_path}.to raise_error ActiveRecord::RecordInvalid }
      end
      context 'when path is empty' do
        let(:path) { '' }
        it { expect{procedure_path}.to raise_error ActiveRecord::RecordInvalid }
      end
      context 'when path contains spaces' do
        let(:path) { 'Demande de subvention' }
        it { expect{procedure_path}.to raise_error ActiveRecord::RecordInvalid }
      end
      context 'when path contains alphanumerics and underscores' do
        let(:path) { 'ma_super_procedure_1' }
        it { expect{procedure_path}.not_to raise_error }
      end
      context 'when path contains dashes' do
        let(:path) { 'ma-super-procedure' }
        it { expect{procedure_path}.not_to raise_error }
      end
      context 'when path is too long' do
        let(:path) { 'ma-super-procedure-12345678901234567890123456789012345678901234567890' }
        it { expect{procedure_path}.to raise_error ActiveRecord::RecordInvalid }
      end
      context 'when path is too short' do
        let(:path) { 'pr' }
        it { expect{procedure_path}.to raise_error ActiveRecord::RecordInvalid }
      end
    end
  end

end
