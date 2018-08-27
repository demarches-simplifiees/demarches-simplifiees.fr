require Rails.root.join("lib", "tasks", "task_helper")

namespace :'2018_08_27_migrate_feedbacks' do
  task run: :environment do
    MAPPING = {
      0 => Feedback.ratings.fetch(:unhappy),
      1 => Feedback.ratings.fetch(:neutral),
      2 => Feedback.ratings.fetch(:happy)
    }

    MAPPING.keys.each do |mark|
      rating = MAPPING[mark]

      Feedback
        .where(mark: mark)
        .update_all(rating: rating)
    end
  end
end
