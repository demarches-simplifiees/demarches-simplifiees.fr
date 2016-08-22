begin
  Administration.create!(email: SUPERADMIN.email, password: SUPERADMIN.password)
rescue ActiveRecord::RecordInvalid
  admin = Administration.find_by_email(SUPERADMIN.email)
  admin.password = SUPERADMIN.password
  admin.save
end
