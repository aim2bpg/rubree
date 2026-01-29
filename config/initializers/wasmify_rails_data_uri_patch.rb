# frozen_string_literal: true

# Patch for wasmify-rails 0.4.0 to handle nil content type
# Issue: request.get_header("HTTP_CONTENT_TYPE") can be nil
Rails.application.config.after_initialize do
  Rack::DataUriUploads.class_eval do
    def call(env)
      return @app.call(env) unless env[Rack::RACK_INPUT]

      request = Rack::Request.new(env)

      content_type = request.get_header("HTTP_CONTENT_TYPE")
      if (
        request.post? || request.put? || request.patch?
      ) && content_type&.match?(%r{multipart/form-data})
        transform_params(request.params)
        env["action_dispatch.request.request_parameters"] = request.params
      end

      @app.call(env)
    end
  end
end
