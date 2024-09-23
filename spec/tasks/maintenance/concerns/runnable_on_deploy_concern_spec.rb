# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Maintenance::RunnableOnDeployConcern do
  let(:test_class) do
    Class.new do
      include Maintenance::RunnableOnDeployConcern
    end
  end

  describe '.run_on_deploy?' do
    context 'when run_on_first_deploy is not set' do
      it 'returns false' do
        expect(test_class.run_on_deploy?).to be false
      end
    end

    context 'when run_on_first_deploy is set' do
      before do
        test_class.run_on_first_deploy
        allow(MaintenanceTasks::TaskDataShow).to receive(:new).and_return(task_data_show)
      end

      let(:task_data_show) { instance_double(MaintenanceTasks::TaskDataShow, completed_runs: completed_runs, active_runs: active_runs) }
      let(:completed_runs) { double(ActiveRecord::Relation, not_errored: not_errored_runs) }
      let(:active_runs) { [] }
      let(:not_errored_runs) { [] }

      context 'when there are no run yet' do
        it 'returns true' do
          expect(test_class.run_on_deploy?).to be true
        end
      end

      context 'when there are completed runs without errors' do
        let(:not_errored_runs) { [instance_double(MaintenanceTasks::Run)] }

        it 'returns false' do
          expect(test_class.run_on_deploy?).to be false
        end
      end

      context 'when there are active runs' do
        let(:active_runs) { [instance_double(MaintenanceTasks::Run)] }

        it 'returns false' do
          expect(test_class.run_on_deploy?).to be false
        end
      end
    end
  end
end
