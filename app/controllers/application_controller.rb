class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

   def after_sign_in_path_for(resource_or_scope)
    admin_root_path
  end

   # for user devise session
  def after_sign_out_path_for(resource_or_scope)
    frontend_user_path(current_user)
  end

end
