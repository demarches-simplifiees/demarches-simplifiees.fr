class ProcedurePathFormatValidator < ActiveModel::Validator

  def path_regex
    /^[a-z0-9_]{3,30}$/
  end

  def validate(record)
    return false if record.path.blank?
    record.errors[:path] << "Path invalide" unless path_regex.match(record.path)
  end

end
