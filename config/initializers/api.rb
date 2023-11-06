require 'socket'

module Api
  module V1

    STATUS_OK = 'ok'
    STATUS_ERROR = 'error'

    E_INVALID_JSON = 1
    E_INVALID_SESSION = 2
    E_ACCESS_DENIED = 3
    E_INTERNAL = 4
    E_SIGNUP_FAILED = 5
    E_INVALID_LOGIN = 6
    E_RESOURCE_NOT_FOUND = 7
    E_INVALID_PARAM = 8
    E_API = 9
    E_METHOD_NOT_FOUND = 10
    E_UNSUPPORTED = 11

    VERSION = '1.0.0'

    DIRECTION = { up: 0, down: 1 }
    TIMESTAMP_TYPE = { updated_at: 0, created_at: 1 }
    LIMIT = 20

    class CatchJsonParseErrors
      def initialize(app)
        @app = app
      end

      def call(env)
        begin
          @app.call(env)
        rescue ActionDispatch::ParamsParser::ParseError => error
          return [
              500,
              { "Content-Type" => "application/json" },
              { status: 'error', error_no: E_INVALID_JSON, message: "There was a problem in the JSON you submitted" }.to_json
          ]
        end
      end
    end

  end
end