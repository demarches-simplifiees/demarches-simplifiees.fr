include ActiveSupport::Testing::TimeHelpers

describe Stat do
  describe '.deleted_dossiers_states' do
    subject { Stat.send(:deleted_dossiers_states) }
    it 'find counts for columns' do
      create(:deleted_dossier, dossier_id: create(:dossier).id, state: :termine)
      create(:deleted_dossier, dossier_id: create(:dossier).id, state: :en_construction, deleted_at: 1.month.ago)
      create(:deleted_dossier, dossier_id: create(:dossier).id, state: :en_construction, deleted_at: 2.months.ago)
      create(:deleted_dossier, dossier_id: create(:dossier).id, state: :brouillon, deleted_at: 3.months.ago)
      create(:deleted_dossier, dossier_id: create(:dossier).id, state: :en_construction, deleted_at: 3.months.ago)
      create(:deleted_dossier, dossier_id: create(:dossier).id, state: :en_instruction, deleted_at: 3.months.ago)
      create(:deleted_dossier, dossier_id: create(:dossier).id, state: :accepte, deleted_at: 3.months.ago)
      create(:deleted_dossier, dossier_id: create(:dossier).id, state: :refuse, deleted_at: 3.months.ago)
      create(:deleted_dossier, dossier_id: create(:dossier).id, state: :sans_suite, deleted_at: 3.months.ago)

      expect(subject["not_brouillon"]).to eq(8)
      expect(subject["dossiers_depose_avant_30_jours"]).to eq(1)
      expect(subject["dossiers_deposes_entre_60_et_30_jours"]).to eq(1)
      expect(subject["brouillon"]).to eq(1)
      expect(subject["en_construction"]).to eq(3)
      expect(subject["en_instruction"]).to eq(1)
      expect(subject["termines"]).to eq(3)
    end
  end

  describe '.update_stats' do
    it 'merges dossiers_states and deleted_dossiers_states' do
      stats = {
        "not_brouillon" => 1,
        "dossiers_depose_avant_30_jours" => 2,
        "dossiers_deposes_entre_60_et_30_jours" => 3,
        "brouillon" => 4,
        "en_construction" => 5,
        "en_instruction" => 6,
        "termines" => 7
      }
      allow(Stat).to receive(:dossiers_states).and_return(stats)
      allow(Stat).to receive(:deleted_dossiers_states).and_return(stats)

      Stat.update_stats
      computed_stats = Stat.first

      expect(computed_stats.dossiers_not_brouillon).to eq(stats["not_brouillon"] * 2)
      expect(computed_stats.dossiers_depose_avant_30_jours).to eq(stats["dossiers_depose_avant_30_jours"] * 2)
      expect(computed_stats.dossiers_deposes_entre_60_et_30_jours).to eq(stats["dossiers_deposes_entre_60_et_30_jours"] * 2)
      expect(computed_stats.dossiers_brouillon).to eq(stats["brouillon"] * 2)
      expect(computed_stats.dossiers_en_construction).to eq(stats["en_construction"] * 2)
      expect(computed_stats.dossiers_en_instruction).to eq(stats["en_instruction"] * 2)
      expect(computed_stats.dossiers_termines).to eq(stats["termines"] * 2)
    end
  end

  describe '.cumulative_hash' do
    it 'works count and cumulate counters by month for both dossier and deleted dossiers' do
      12.downto(1).map do |i|
        create(:dossier, state: :en_construction, depose_at: i.months.ago)
        create(:deleted_dossier, dossier_id: i + 100, state: :en_construction, deleted_at: i.month.ago)
      end
      rs = Stat.send(:cumulative_month_serie, [
        [Dossier.state_not_brouillon, :depose_at],
        [DeletedDossier.where.not(state: :brouillon), :deleted_at]
      ])
      expect(rs).to eq({
        12 => 2,
        11 => 4,
        10 => 6,
        9 => 8,
        8 => 10,
        7 => 12,
        6 => 14,
        5 => 16,
        4 => 18,
        3 => 20,
        2 => 22,
        1 => 24
      }.transform_keys { |i| i.months.ago.beginning_of_month.to_date })
    end
  end

  describe '.last_four_months_hash' do
    it 'works count and cumulate counters by month for both dossier and deleted dossiers' do
      travel_to Time.zone.local(2021, 11, 25) do
        4.downto(1).map do |i|
          create(:dossier, state: :en_construction, depose_at: i.months.ago)
          create(:deleted_dossier, dossier_id: i + 100, state: :en_construction, deleted_at: i.month.ago)
        end
        rs = Stat.send(:last_four_months_serie, [
          [Dossier.state_not_brouillon, :depose_at],
          [DeletedDossier.where.not(state: :brouillon), :deleted_at]
        ])
        expect(rs).to eq({
          "juillet 2021" => 2,
          "août 2021" => 2,
          "septembre 2021" => 2,
          "octobre 2021" => 2
        })
      end
    end
  end

  describe '.sum_hashes' do
    it 'sum up hashes keys' do
      expect(Stat.send(:sum_hashes, *[{ a: 1, b: 2, d: 5 }, { a: 2, b: 3, c: 5 }])).to eq({ a: 3, b: 5, c: 5, d: 5 })
    end
  end
end
