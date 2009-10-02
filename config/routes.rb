ActionController::Routing::Routes.draw do |map|
  map.resources :scalings, :only => [ :index, :show ]
  map.resource :observation_range, :only => :show
  map.root :controller => "scalings", :action => "index"
end
