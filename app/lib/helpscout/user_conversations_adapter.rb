# Fetch and compute monthly reports about the users conversations on Helpscout
class Helpscout::UserConversationsAdapter
  EXCLUDED_TAGS = ['openlab', 'bizdev', 'admin', 'webinaire']

  def initialize(from, to)
    @from = from
    @to = to
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
    report = fetch_conversations_report(year, month)

    total_conversations = report.dig(:current, :totalConversations)
    excluded_conversations = report
      .dig(:tags, :top)
      .select { |tag| tag[:name]&.in?(EXCLUDED_TAGS) }
      .map { |tag| tag[:count] }
      .sum

    {
      start_date: report.dig(:current, :startDate).to_datetime,
      end_date: report.dig(:current, :endDate).to_datetime,
      conversations_count: total_conversations - excluded_conversations
    }
  end

  def fetch_conversations_report(year, month)
    if year == Date.today.year && month == Date.today.month
      raise ArgumentError, 'The report for the current month will change in the future, and cannot be cached.'
    end

    @helpscout_api ||= Helpscout::API.new

    Rails.cache.fetch("helpscout-conversation-report-#{year}-#{month}") do
      @helpscout_api.conversations_report(year, month)
    end
  end
end
