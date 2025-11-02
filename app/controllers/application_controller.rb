class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :set_locale

  private

  def set_locale
    if params[:locale].present?
      session[:locale] = params[:locale]
    end

    I18n.locale = session[:locale].presence || I18n.default_locale
  end

  def extract_locale_from_accept_language_header
    return nil unless request&.env&.[]("HTTP_ACCEPT_LANGUAGE")

    locale = request.env["HTTP_ACCEPT_LANGUAGE"].scan(/^[a-z]{2}/).first
    locale if I18n.available_locales.map(&:to_s).include?(locale)
  end
end
