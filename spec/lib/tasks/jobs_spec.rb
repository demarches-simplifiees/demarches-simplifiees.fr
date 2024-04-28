# frozen_string_literal: true

describe 'jobs' do
  describe 'schedule' do
    subject { Rake::Task['jobs:schedule'].invoke }
    it 'runs' do
      expect { subject }.not_to raise_error
    end
  end
end
