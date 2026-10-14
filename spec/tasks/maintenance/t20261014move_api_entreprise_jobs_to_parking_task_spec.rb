# frozen_string_literal: true

require "rails_helper"

module Maintenance
  RSpec.describe T20261014moveAPIEntrepriseJobsToParkingTask do
    describe "#process" do
      let(:procedure) { procedures.entreprise }
      let(:etablissements) { create_list(:etablissement, 4) }
      let(:garage) { Sidekiq::Queue.new("garage") }
      let(:default) { Sidekiq::Queue.new("default") }
      let(:low) { Sidekiq::Queue.new("low") }
      let(:retries) { Sidekiq::RetrySet.new }
      let(:scheduled) { Sidekiq::ScheduledSet.new }

      after { [garage, default, low, retries, scheduled].each(&:clear) }

      def item(job, queue:, created_at:)
        {
          "class" => "Sidekiq::ActiveJob::Wrapper",
          "wrapped" => job.class.name,
          "queue" => queue,
          "args" => [job.serialize],
          "jid" => SecureRandom.hex(12),
          "created_at" => (created_at.to_f * 1000).to_i,
        }
      end

      def push(key, job, created_at:, queue: "garage")
        Sidekiq.redis { it.lpush(key, Sidekiq.dump_json(item(job, queue:, created_at:))) }
      end

      def bilans(etablissement_id) = APIEntreprise::BilansBdfJob.new(etablissement_id, procedure.id)

      def run!
        task = described_class.new
        task.collection.each { task.process(it) }
      end

      let(:fetches) { ParkedAPIEntrepriseFetch.where(etablissement: etablissements).order(:etablissement_id) }

      before do
        stub_const("#{described_class}::BATCH_SIZE", 2)

        push("queue:garage", bilans(etablissements[0].id), created_at: 40.days.ago)
        push("queue:garage", APIEntreprise::TvaJob.new(etablissements[0].id, procedure.id), created_at: 3.days.ago)
        push("queue:garage", bilans(etablissements[0].id), created_at: 2.days.ago)
        push("queue:garage", bilans(0), created_at: 2.days.ago)
        push("queue:default", bilans(etablissements[1].id), created_at: 1.day.ago, queue: "default")
        push("queue:default", APIEntreprise::TvaJob.new(etablissements[1].id, procedure.id), created_at: 1.day.ago, queue: "default")
        push("queue:low", bilans(etablissements[2].id), created_at: 5.days.ago, queue: "low")
        Sidekiq.redis { it.zadd("retry", 1.hour.from_now.to_f, Sidekiq.dump_json(item(bilans(etablissements[3].id), queue: "default", created_at: 10.days.ago))) }
        Sidekiq.redis { it.zadd("schedule", 1.hour.from_now.to_f, Sidekiq.dump_json(item(bilans(etablissements[3].id), queue: "default", created_at: 9.days.ago))) }
      end

      it "parks the jobs of the class with their creation date and removes them from Redis" do
        run!

        expect(fetches.map { [it.etablissement_id, it.job, it.procedure_id, it.arguments, it.code] }).to eq(
          etablissements.map { [it.id, "BilansBdfJob", procedure.id, [it.id, procedure.id], 503] }
        )
        expect(fetches.map { it.created_at.to_date }).to eq([40.days.ago, 1.day.ago, 5.days.ago, 10.days.ago].map(&:to_date))

        expect(garage.map(&:display_class)).to eq(["APIEntreprise::TvaJob"])
        expect(default.map(&:display_class)).to eq(["APIEntreprise::TvaJob"])
        expect(low.size).to eq(0)
        expect(retries.size).to eq(0)
        expect(scheduled.size).to eq(0)
      end

      it "dates a fetch already parked by the job when it was older" do
        ParkedAPIEntrepriseFetch.park!(etablissement_id: etablissements[1].id, job: "BilansBdfJob", procedure_id: procedure.id, arguments: [etablissements[1].id, procedure.id], code: 503)

        run!

        expect(fetches.find_by(etablissement: etablissements[1]).created_at.to_date).to eq(1.day.ago.to_date)
      end
    end
  end
end
