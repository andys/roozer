class ApplicationController < ActionController::Base
  before_filter do
    Roozer::Application.clear_doozer
    true
  end
end
