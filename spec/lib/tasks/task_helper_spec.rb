require 'spec_helper'

describe ProgressReport, lib: true do
  context 'when the count pass above 100%' do
    let(:total) { 2 }

    subject(:progress) { ProgressReport.new(total) }

    it 'doesn’t raise errors' do
      expect do
        (total + 2).times { progress.inc }
        progress.finish
      end.not_to raise_error
    end
  end
end
