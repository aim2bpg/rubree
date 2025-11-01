class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  before_action :set_locale

  private

  # Set I18n.locale from params[:locale] (and persist in session). Falls back to session or default.
  def set_locale
    if params[:locale].present?
      session[:locale] = params[:locale]
    end

    # Prefer an explicitly set session locale (via params[:locale]).
    # When none is set, default to the app's default locale (typically :en)
    # rather than automatically falling back to the browser Accept-Language header.
    # This keeps the view default consistently in English unless the user chooses otherwise.
    I18n.locale = session[:locale].presence || I18n.default_locale
  end

  def extract_locale_from_accept_language_header
    return nil unless request&.env&.[]("HTTP_ACCEPT_LANGUAGE")
    locale = request.env["HTTP_ACCEPT_LANGUAGE"].scan(/^[a-z]{2}/).first
    locale if I18n.available_locales.map(&:to_s).include?(locale)
  end
end
