ActionController::Routing::Routes.draw do |map|
  map.resources :scalings, :only => [ :index, :update ] do |scaling|
    scaling.resource :chart, :only => :show
    scaling.resource :statistic, :only => :show
  end
  map.resource :observation_range, :only => :show
  map.root :controller => "scalings", :action => "index"
end
