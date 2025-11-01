require 'rails_helper'

RSpec.describe ApplicationController do
  # Create an anonymous controller that inherits ApplicationController so we can
  # exercise the private method via controller instance and have a route to call.
  controller(described_class) do
    def index
      head :ok
    end
  end

  describe '#extract_locale_from_accept_language_header' do
    it 'returns nil when Accept-Language header is not present' do
      request.env.delete('HTTP_ACCEPT_LANGUAGE')
      expect(controller.send(:extract_locale_from_accept_language_header)).to be_nil
    end

    it 'returns the first two-letter locale when it is available' do
      request.env['HTTP_ACCEPT_LANGUAGE'] = 'ja,en-US;q=0.9'
      expect(controller.send(:extract_locale_from_accept_language_header)).to eq('ja')
    end

    it 'returns nil when the extracted locale is not in I18n.available_locales' do
      request.env['HTTP_ACCEPT_LANGUAGE'] = 'zz,en-US;q=0.9'
      expect(controller.send(:extract_locale_from_accept_language_header)).to be_nil
    end
  end

  describe '#set_locale' do
    around do |example|
      prev = I18n.locale
      example.run
      I18n.locale = prev
    end

    it 'stores locale in session and sets I18n.locale when params[:locale] present' do
      get :index, params: { locale: 'ja' }
      expect(session[:locale]).to eq('ja')
      expect(I18n.locale.to_s).to eq('ja')
    end

    it 'falls back to default locale when no session or params present' do
      session.delete(:locale)
      get :index
      expect(I18n.locale).to eq(I18n.default_locale)
    end
  end
end
