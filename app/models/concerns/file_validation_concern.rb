module FileValidationConcern
  extend ActiveSupport::Concern
  class_methods do
    def file_size_validation(file_max_size = 200.megabytes)
      { less_than: file_max_size, message: I18n.t('errors.messages.file_size_out_of_range', file_size_limit: ActiveSupport::NumberHelper.number_to_human_size(file_max_size)) }
    end
  end
end
