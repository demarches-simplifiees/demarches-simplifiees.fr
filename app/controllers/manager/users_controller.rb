module Manager
  class UsersController < Manager::ApplicationController
    def resend_confirmation_instructions
      user = User.find(params[:id])
      user.resend_confirmation_instructions
      flash[:notice] = "L'email d'activation de votre compte a été renvoyé."
      redirect_to manager_user_path(user)
    end

    def sent_emails
      @user = User.find(params[:id])

      contactId = fetch_contact_id(@user.email)
      @messages = fetch_messages(@contactId)
    end
    
    def auth
      "#{ENV['MAILJET_API_KEY']}:#{ENV['MAILJET_SECRET_KEY']}"
    end

    def fetch_contact_id(email)
      response = Typhoeus.get(
        "https://api.mailjet.com/v3/REST/contact/#{email}",
        userpwd: auth
      )

      if response.success? 
        contact = JSON.parse(response.body)
        return contact.dig('Data', 0, 'ID')
      end
      return nil
    end

    def fetch_messages(contactId)
      response = Typhoeus.get(
        "https://api.mailjet.com/v3/REST/message/?ContactId=#{contactId}",
        userpwd: auth
      )

      if response.success? 
        messages = JSON.parse(response.body).dig('Data')
        return messages
      end
      return []
    end
  end
end
