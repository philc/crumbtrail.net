ActionController::Routing::Routes.draw do |map|
  # The priority is based upon order of creation: first created -> highest priority.
  
  # Sample of regular route:
  # map.connect 'products/:id', :controller => 'catalog', :action => 'view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  # map.purchase 'products/:id/purchase', :controller => 'catalog', :action => 'purchase'
  # This route can be invoked with purchase_url(:id => product.id)

  # You can have the root of your site routed by hooking up '' 
  # -- just remember to delete public/index.html.
  # map.connect '', :controller => "welcome"
  map.connect '/', :controller=>'main'
  
  map.connect '/signout', :controller=>'main',:action=>'signout'
  map.connect '/signin', :controller=>'main', :action=>'signin'
  map.connect '/about', :controller=>'main',:action=>'about'
  map.connect '/signup', :controller=>'main',:action=>'signup'
  # Allow downloading Web Service WSDL as a file with an extension
  # instead of a file named 'wsdl'
  map.connect ':controller/service.wsdl', :action => 'wsdl'

  map.connect '/project/new', :controller=>'project', :action=>'new'
  #map.connect '/project/recent', :controller=>'project', :action=>'recent'
  map.connect '/project/all', :controller=>'project', :action=>'all'
  map.connect '/project/save_options', :controller=>'project', :action=>'save_options'
  map.connect '/project/code', :controller=>'project', :action=>"code"
  map.connect '/project/:id', :controller=>'project', :action=>"index"
  # Install the default route as the lowest priority.
  
  map.connect '/feed/:id/:action/:option', :controller=>'feed'  
  map.connect '/feed/:id/:action/', :controller=>'feed'
  map.connect ':controller/:action/:id'
  
  
end
