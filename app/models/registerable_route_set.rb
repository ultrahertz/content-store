class RegisterableRouteSet < OpenStruct

  def initialize(hash = nil)
    super
    self.registerable_routes ||= []
    self.registerable_redirects ||= []
  end

  include ActiveModel::Validations

  validate :registerable_routes_and_redirects_are_valid,
           :all_routes_and_redirects_are_beneath_base_path,
           :all_routes_and_redirects_have_unique_paths,
           :redirect_cannot_have_routes
  validate :registerable_routes_include_base_path, :if => :base_path_route_required?
  validate :registerable_redirects_include_base_path, :if => :is_redirect

  # +item.routes+ should be an array of hashes containing both a 'path' and a
  # 'type' key. 'path' defines the absolute URL path to the content and 'type'
  # is either 'exact' or 'prefix', depending on the type of route. For example:
  #
  #   [ { 'path' => '/content', 'type' => 'exact' },
  #     { 'path' => '/content.json', 'type' => 'exact' },
  #     { 'path' => '/content/subpath', 'type' => 'prefix' } ]
  #
  # +item.redirects+ should be an array of hashes containin a 'path', 'type' and
  # a 'destination' key.  'path' and 'type' are as above, 'destination' it the target
  # path for the redirect.
  #
  # All paths must be below the +base_path+ and +base_path+  must be defined as
  # a route for the routes to be valid.
  def self.from_content_item(item)
    registerable_routes = item.routes.map do |attrs|
      route_type = item.gone? ? RegisterableGoneRoute : RegisterableRoute
      route_type.new(attrs.slice("path", "type"))
    end
    registerable_redirects = item.redirects.map do |attrs|
      RegisterableRedirect.new(attrs.slice("path", "type", "destination"))
    end

    new({
      :registerable_routes => registerable_routes,
      :registerable_redirects => registerable_redirects,
      :base_path => item.base_path,
      :rendering_app => item.rendering_app,
      :is_redirect => item.redirect?,
      :is_gone => item.gone?,
    })
  end

  def self.from_publish_intent(intent)
    route_set = new({
      :base_path => intent.base_path,
      :rendering_app => intent.rendering_app,
    })
    route_attrs = intent.routes
    if item = intent.content_item
      # if a content item exists we only want to register the set of routes
      # that don't already exist on the item
      route_attrs -= item.routes
      route_set.is_supplimentary_set = true
    end
    route_set.registerable_routes = route_attrs.map do |attrs|
      RegisterableRoute.new(attrs.slice("path", "type"))
    end
    route_set
  end

  def register!
    return unless registerable_routes.any? || registerable_redirects.any?
    if is_redirect
      registerable_redirects.map(&:register!)
    elsif is_gone
      registerable_routes.map(&:register!)
    else
      register_rendering_app
      registerable_routes.each { |route| route.register!(rendering_app) }
    end
    commit_routes
  end

private

  def base_path_route_required?
    ! self.is_redirect && ! self.is_supplimentary_set
  end

  def register_rendering_app
    Rails.application.router_api.add_backend(rendering_app, Plek.find(rendering_app, :force_http => true) + "/")
  end

  def commit_routes
    Rails.application.router_api.commit_routes
  end

  def registerable_routes_and_redirects_are_valid
    unless registerable_routes.all?(&:valid?)
      errors[:registerable_routes] << "are invalid"
    end
    unless registerable_redirects.all?(&:valid?)
      errors[:registerable_redirects] << "are invalid"
    end
  end

  def registerable_routes_include_base_path
    route_paths = registerable_routes.map(&:path)
    unless route_paths.include?(base_path)
      errors[:registerable_routes] << 'must include the base_path'
    end
  end

  def registerable_redirects_include_base_path
    paths = registerable_redirects.map(&:path)
    unless paths.include?(base_path)
      errors[:registerable_redirects] << 'must include the base_path'
    end
  end

  def all_routes_and_redirects_are_beneath_base_path
    unless registerable_routes.all? {|route| base_path_with_extension?(route) || beneath_base_path?(route) }
      errors[:registerable_routes] << 'must be below the base path'
    end
    unless registerable_redirects.all? {|redirect| base_path_with_extension?(redirect) || beneath_base_path?(redirect) }
      errors[:registerable_redirects] << 'must be below the base path'
    end
  end

  def all_routes_and_redirects_have_unique_paths
    paths = registerable_routes.map(&:path)
    unless paths == paths.uniq
      errors[:registerable_routes] << 'must have unique paths'
    end

    paths = registerable_redirects.map(&:path)
    unless paths == paths.uniq
      errors[:registerable_redirects] << 'must have unique paths'
    end
  end

  def redirect_cannot_have_routes
    if self.is_redirect && self.registerable_routes.any?
      errors[:registerable_routes] << 'redirect items cannot have routes'
    end
  end

  def base_path_with_extension?(route)
    route.path.match(%r(^#{base_path}\.\w+\z))
  end

  def beneath_base_path?(route)
    base_segments = segments_for(route.path)[0,base_path_segments.size]
    base_segments == base_path_segments
  end

  def base_path_segments
    @base_path_segments ||= segments_for(base_path)
  end

  def segments_for(path)
    path.split('/').reject(&:blank?)
  end
end
