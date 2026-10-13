# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20261012purgeOutOfScopeAPIEntrepriseJobsTask do
    describe "#process" do
      subject(:process) { described_class.new.process }

      let(:adapter) { ActiveJob::QueueAdapters::SidekiqAdapter.new }
      let(:scheduled) { Sidekiq::ScheduledSet.new }
      let(:retries) { Sidekiq::RetrySet.new }
      let(:dead) { Sidekiq::DeadSet.new }

      let(:company) { create(:etablissement) }
      let(:state_service) { create(:etablissement, entreprise_forme_juridique_code: '7120') }
      let(:non_employer) { create(:etablissement, entreprise_code_effectif_entreprise: 'NN') }

      around do |example|
        [scheduled, retries, dead].each(&:clear)
        example.run
        [scheduled, retries, dead].each(&:clear)
      end

      def add(set, job)
        item = { "class" => "Sidekiq::ActiveJob::Wrapper", "wrapped" => job.class.name, "queue" => job.queue_name, "args" => [job.serialize], "jid" => job.job_id }
        Sidekiq.redis { it.zadd(set, 1.hour.from_now.to_f, Sidekiq.dump_json(item)) }
      end

      def remaining(source) = source.map { [it.display_class, it.display_args.first] }

      before do
        adapter.enqueue_at(APIEntreprise::ExtraitKbisJob.new(state_service.id, 1), 1.hour.from_now.to_f)
        add("retry", APIEntreprise::ExercicesJob.new(state_service.id, 1))
        add("retry", APIEntreprise::ExercicesJob.new(company.id, 1))
        add("retry", APIEntreprise::TvaJob.new(state_service.id, 1))
        add("retry", APIEntreprise::AssociationJob.new(company.id, 1))
        add("retry", APIEntreprise::AssociationJob.new(0, 1))
        add("dead", APIEntreprise::EffectifsJob.new(non_employer.id, 1))
      end

      it "removes the scheduled, retrying and dead jobs of etablissements out of the API's scope, or gone" do
        process

        expect(remaining(scheduled)).to eq([])
        expect(remaining(retries)).to match_array([
          ["APIEntreprise::ExercicesJob", company.id],
          ["APIEntreprise::TvaJob", state_service.id],
        ])
        expect(remaining(dead)).to eq([])
      end
    end
  end
end
