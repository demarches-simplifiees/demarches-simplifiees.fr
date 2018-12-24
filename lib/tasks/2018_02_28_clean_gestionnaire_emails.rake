namespace :'2018_02_28_clean_invalid_emails_accounts' do
  task clean: :environment do
    Gestionnaire.pluck(:email, :id).select { |e, _id| e.include?(" ") }.each do |_email, id|
      Gestionnaire.find_by(id: id, current_sign_in_at: nil)&.destroy # ensure account was never used
    end

    User.pluck(:email, :id).select { |e, _id| e.include?(" ") }.each do |_email, id|
      User.find_by(id: id, current_sign_in_at: nil)&.destroy # ensure account was never used
    end
  end
end
