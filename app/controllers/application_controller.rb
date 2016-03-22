class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  # For APIs, you may want to use :null_session instead.
  # protect_from_forgery with: :null_session
  # remove the line below in >= devise 3.3.0
  skip_before_filter :verify_authenticity_token

  # respond_to :json, :html

  before_action :authenticate_user!
  before_filter :configure_permitted_parameters, if: :devise_controller?

  def authorize_admin
    redirect_to root_path, alert: 'Access Denied' unless current_user.admin?
  end


  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:email, :password, :password_confirmation, :remember_me) }
    devise_parameter_sanitizer.for(:sign_in) { |u| u.permit(:email, :password, :remember_me) }
    devise_parameter_sanitizer.for(:sign_out) { |u| u.permit(:email, :password, :remember_me) }
    devise_parameter_sanitizer.for(:account_update) { |u| u.permit(:email, :password, :password_confirmation, :current_password) }
  end


  private

  def after_sign_out_path_for(resource_or_scope)
    root_path
  end

end
