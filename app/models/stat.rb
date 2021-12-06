# == Schema Information
#
# Table name: stats
#
#  id                                    :bigint           not null, primary key
#  administrations_partenaires           :bigint           default(0)
#  dossiers_brouillon                    :bigint           default(0)
#  dossiers_cumulative                   :jsonb            not null
#  dossiers_depose_avant_30_jours        :bigint           default(0)
#  dossiers_deposes_entre_60_et_30_jours :bigint           default(0)
#  dossiers_en_construction              :bigint           default(0)
#  dossiers_en_instruction               :bigint           default(0)
#  dossiers_in_the_last_4_months         :jsonb            not null
#  dossiers_not_brouillon                :bigint           default(0)
#  dossiers_termines                     :bigint           default(0)
#  created_at                            :datetime         not null
#  updated_at                            :datetime         not null
#
class Stat < ApplicationRecord
  class << self
    def update_stats
      states = sum_hashes(dossiers_states, deleted_dossiers_states)
      stat = Stat.first || Stat.new

      stat.update(
        dossiers_en_construction: states['en_construction'],
        dossiers_en_instruction: states['en_instruction'],
        dossiers_brouillon: states['brouillon'],
        dossiers_depose_avant_30_jours: states['dossiers_depose_avant_30_jours'],
        dossiers_deposes_entre_60_et_30_jours: states['dossiers_deposes_entre_60_et_30_jours'],
        dossiers_not_brouillon: states['not_brouillon'],
        dossiers_termines: states['termines'],
        dossiers_cumulative: cumulative_hash([
          [Dossier.state_not_brouillon, :depose_at],
          [DeletedDossier.where.not(state: :brouillon), :deleted_at]
        ]),
        dossiers_in_the_last_4_months: last_four_months_hash([
          [Dossier.state_not_brouillon, :depose_at],
          [DeletedDossier.where.not(state: :brouillon), :deleted_at]
        ]),
        administrations_partenaires: AdministrateursProcedure.joins(:procedure).merge(Procedure.publiees_ou_closes).select('distinct administrateur_id').count
      )
    end

    private

    def dossiers_states
      sanitize_and_exec(Dossier, <<-EOF
        SELECT
          COUNT(*) FILTER ( WHERE state != 'brouillon' ) AS "not_brouillon",
          COUNT(*) FILTER ( WHERE state != 'brouillon' and depose_at BETWEEN :one_month_ago AND :now ) AS "dossiers_depose_avant_30_jours",
          COUNT(*) FILTER ( WHERE state != 'brouillon' and depose_at BETWEEN :two_months_ago AND :one_month_ago ) AS "dossiers_deposes_entre_60_et_30_jours",
          COUNT(*) FILTER ( WHERE state = 'brouillon' ) AS "brouillon",
          COUNT(*) FILTER ( WHERE state = 'en_construction' ) AS "en_construction",
          COUNT(*) FILTER ( WHERE state = 'en_instruction' ) AS "en_instruction",
          COUNT(*) FILTER ( WHERE state in ('accepte', 'refuse', 'sans_suite') ) AS "termines"
        FROM dossiers
        WHERE hidden_at IS NULL
      EOF
      )
    end

    def deleted_dossiers_states
      sanitize_and_exec(DeletedDossier, <<-EOF
        SELECT
          COUNT(*) FILTER ( WHERE state != 'brouillon' ) AS "not_brouillon",
          COUNT(*) FILTER ( WHERE state != 'brouillon' and deleted_at BETWEEN :one_month_ago AND :now ) AS "dossiers_depose_avant_30_jours",
          COUNT(*) FILTER ( WHERE state != 'brouillon' and deleted_at BETWEEN :two_months_ago AND :one_month_ago ) AS "dossiers_deposes_entre_60_et_30_jours",
          COUNT(*) FILTER ( WHERE state = 'brouillon' ) AS "brouillon",
          COUNT(*) FILTER ( WHERE state = 'en_construction' ) AS "en_construction",
          COUNT(*) FILTER ( WHERE state = 'en_instruction' ) AS "en_instruction",
          COUNT(*) FILTER ( WHERE state in ('accepte', 'refuse', 'sans_suite') ) AS "termines"
        FROM deleted_dossiers
      EOF
      )
    end

    def last_four_months_hash(associations_with_date_attribute)
      min_date = 3.months.ago.beginning_of_month.to_date
      timeseries = associations_with_date_attribute.map do |association, date_attribute|
        association
          .where(date_attribute => min_date..max_date)
          .group("DATE_TRUNC('month', #{date_attribute})")
          .count
      end

      sum_hashes(*timeseries)
        .to_a
        .sort_by { |a| a[0] }
        .map { |e| [I18n.l(e.first, format: "%B %Y"), e.last] }
    end

    def cumulative_hash(associations_with_date_attribute)
      timeseries = associations_with_date_attribute.map do |association, date_attribute|
        association
          .where("#{date_attribute} < ?", max_date)
          .group("DATE_TRUNC('month', #{date_attribute})")
          .count
      end

      sum = 0
      sum_hashes(*timeseries)
        .to_a
        .sort_by { |a| a[0] }
        .map { |x, y| { x => (sum += y) } }
        .reduce({}, :merge)
    end

    def sum_hashes(*hashes)
      {}.merge(*hashes) { |_k, hash_one_value, hash_two_value| hash_one_value + hash_two_value }
    end

    def max_date
      Time.zone.now.beginning_of_month - 1.second
    end

    def sanitize_and_exec(model, query)
      sanitized_query = ActiveRecord::Base.sanitize_sql([
        query,
        now: Time.zone.now,
        one_month_ago: 1.month.ago,
        two_months_ago: 2.months.ago
      ])
      model.connection.select_all(sanitized_query).first
    end
  end
end
