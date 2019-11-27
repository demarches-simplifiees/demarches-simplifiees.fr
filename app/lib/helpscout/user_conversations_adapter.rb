# Fetch and compute monthly reports about the users conversations on Helpscout
class Helpscout::UserConversationsAdapter
  def initialize(from, to)
    @from = from
    @to = to
  end

  def can_fetch_reports?
    api_client.ready?
  end

  # Return an array of monthly reports
  def reports
    @reports ||= (@from..@to)
      .group_by { |date| [date.year, date.month] }
      .keys
      .map { |key| { year: key[0], month: key[1] } }
      .map { |interval| report(interval[:year], interval[:month]) }
  end

  private

  def report(year, month)
    report = fetch_productivity_report(year, month)

    {
      start_date:   report.dig(:current, :startDate).to_datetime,
      end_date:     report.dig(:current, :endDate).to_datetime,
      replies_sent: report.dig(:current, :repliesSent)
    }
  end

  def api_client
    @api_client ||= Helpscout::API.new
  end

  def fetch_productivity_report(year, month)
    if year == Time.zone.today.year && month == Time.zone.today.month
      raise ArgumentError, 'The report for the current month will change in the future, and cannot be cached.'
    end

    Rails.cache.fetch("helpscout-productivity-report-#{year}-#{month}") do
      api_client.productivity_report(year, month)
    end
  end
end
