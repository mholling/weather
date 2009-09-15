ActionController::Routing::Routes.draw do |map|
  map.resources :instruments, :only => :index do |instrument|
    instrument.resources :observations, :only => :index
  end
end
