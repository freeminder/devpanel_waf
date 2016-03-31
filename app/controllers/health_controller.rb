class HealthController < ActionController::Base
  def index
    render html: "OK"
  end
end
