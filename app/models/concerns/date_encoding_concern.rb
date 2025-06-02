# frozen_string_literal: true

module DateEncodingConcern
  extend ActiveSupport::Concern

  def match_encoded_date?(field, encoded_date)
    datetime = send(field)
    if (match = encoded_date.match(/([0-9a-f]{8})-([0-9a-f]{0,8})/))
      seconds, nseconds = match.captures.map { |x| x.to_i(16) }
      seconds == datetime.to_i && nseconds == datetime.nsec
    else
      false
    end
  end

  def encoded_date(field)
    datetime = send(field)
    datetime.to_i.to_s(16) + '-' + datetime.nsec.to_s(16) if datetime
  end
end
