require 'rails_helper'

describe "routing of publish_intent requests", :type => :routing do
  context "GET route" do
    it "should route to the controller passing on the base_path" do
      expect(:get => "/publish-intent/foo/bar").to route_to({
        :controller => "publish_intents",
        :action => "show",
        :base_path => "/foo/bar",
      })
    end

    it "should not match a base_path without a leading /" do
      expect(:get => "/publish-intentfoo").not_to be_routable
    end

    it "should require a base_path" do
      expect(:get => "/publish-intent").not_to be_routable
    end
  end

  context "PUT route" do
    it "should route to the controller passing on the base_path" do
      expect(:put => "/publish-intent/foo/bar").to route_to({
        :controller => "publish_intents",
        :action => "update",
        :base_path => "/foo/bar",
      })
    end

    it "should not match a base_path without a leading /" do
      expect(:put => "/publish-intentfoo").not_to be_routable
    end

    it "should require a base_path" do
      expect(:put => "/publish-intent").not_to be_routable
    end
  end

  context "DELETE route" do
    it "should route to the controller passing on the base_path" do
      expect(:delete => "/publish-intent/foo/bar").to route_to({
        :controller => "publish_intents",
        :action => "destroy",
        :base_path => "/foo/bar",
      })
    end

    it "should not match a base_path without a leading /" do
      expect(:delete => "/publish-intentfoo").not_to be_routable
    end

    it "should require a base_path" do
      expect(:delete => "/publish-intent").not_to be_routable
    end
  end
end
