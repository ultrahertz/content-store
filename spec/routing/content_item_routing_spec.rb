require 'rails_helper'

describe "routing of content_item requests", :type => :routing do
  context "GET route" do
    it "should route to the controller passing on the base_path" do
      expect(:get => "/content/foo/bar").to route_to({
        :controller => "content_items",
        :action => "show",
        :base_path => "/foo/bar",
      })
    end

    it "should not match a base_path without a leading /" do
      expect(:get => "/contentfoo").not_to be_routable
    end

    it "should require a base_path" do
      expect(:get => "/content").not_to be_routable
    end
  end

  context "GET API route" do
    it "should route to the controller passing on the base_path" do
      expect(:get => "/api/content/foo/bar").to route_to({
        :controller => "content_items",
        :action => "show",
        :base_path => "/foo/bar",
        :public_api_request => true,
      })
    end

    it "should not match a base_path without a leading /" do
      expect(:get => "/api/contentfoo").not_to be_routable
    end

    it "should require a base_path" do
      expect(:get => "/api/content").not_to be_routable
    end
  end

  context "PUT route" do
    it "should route to the controller passing on the base_path" do
      expect(:put => "/content/foo/bar").to route_to({
        :controller => "content_items",
        :action => "update",
        :base_path => "/foo/bar",
      })
    end

    it "should not match a base_path without a leading /" do
      expect(:put => "/contentfoo").not_to be_routable
    end

    it "should require a base_path" do
      expect(:put => "/content").not_to be_routable
    end
  end

  context "PUT API route" do
    it "should not route with a base_path" do
      expect(:put => "/api/content/foo/bar").not_to be_routable
    end

    it "should not route a base_path without a leading /" do
      expect(:put => "/api/contentfoo").not_to be_routable
    end

    it "should not route without a base_path" do
      expect(:put => "/api/content").not_to be_routable
    end
  end
end
