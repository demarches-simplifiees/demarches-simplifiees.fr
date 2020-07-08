class JwtTokenValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    begin
      JWT.decode value, nil, false
    rescue
      record.errors[attribute] << (options[:message] || "n'est pas un jeton valide")
    end
  end
end
