module Users
  class PasswordsController < Devise::PasswordsController
    # POST /resource/password
    def create
      self.resource = resource_class.send_reset_password_instructions(resource_params)
      yield resource if block_given?

      if successfully_sent?(resource)
        respond_to do |format|
          format.html { 
            redirect_to after_sending_reset_password_instructions_path_for(resource_name), 
            notice: t("devise.passwords.send_paranoid_instructions") 
          }
          format.json { render json: { message: t("devise.passwords.send_paranoid_instructions") }, status: :ok }
        end
      else
        respond_to do |format|
          format.html {
            respond_with(resource)
          }
          format.json { render json: resource.errors, status: :unprocessable_entity }
        end
      end
    end

    # PUT /resource/password
    def update
      self.resource = resource_class.reset_password_by_token(resource_params)
      yield resource if block_given?

      if resource.errors.empty?
        resource.unlock_access! if unlockable?(resource)
        if Devise.sign_in_after_reset_password
          flash_message = resource.active_for_authentication? ? :updated : :updated_not_active
          set_flash_message!(:notice, flash_message)
          resource.after_database_authentication
          sign_in(resource_name, resource)
        else
          set_flash_message!(:notice, :updated_not_active)
        end
        respond_with resource, location: after_resetting_password_path_for(resource)
      else
        set_minimum_password_length
        respond_with resource
      end
    end

    protected

    def after_resetting_password_path_for(resource)
      root_path
    end

    def after_sending_reset_password_instructions_path_for(resource_name)
      new_session_path(resource_name) if is_navigational_format?
    end
  end
end