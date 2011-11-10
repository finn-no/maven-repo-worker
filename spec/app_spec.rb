require File.expand_path("../../app", __FILE__)
require 'rack/test'
require 'json'

module MyHelpers
  def app
    MavenService
  end
end
RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.include MyHelpers
  
end



describe MavenService do
  context "get version" do
    it "get version" do
      artifact = {
      :repo => "http://repo1.maven.org/maven2/", 
      :groupid => "org.apache.cassandra",
      :artifactid => "apache-cassandra"
      }
      post  '/getCurrentVersion', 'json' => artifact.to_json
      last_response.should be_ok
    end
  end
  context "get url" do
    it "get url with json post" do
      artifact = {
      :repo => "http://repo1.maven.org/maven2/", 
      :groupid => "org.apache.cassandra",
      :artifactid => "apache-cassandra"
      }
      post  '/getUrl', 'json' => artifact.to_json
      last_response.should be_ok
    end
    it "get url with json post, specific version" do
      artifact = {
      :repo => "http://repo1.maven.org/maven2/", 
      :groupid => "org.apache.cassandra",
      :artifactid => "apache-cassandra",
      :version => "0.7.6"
      }
      post  '/getUrl', 'json' => artifact.to_json
      last_response.should be_ok
      last_response.body.should match "0.7.6"

   end
   it "get url with get request" do
      artifact = {
      :repo => "http://repo1.maven.org/maven2", 
      :groupid => "org.apache.cassandra",
      :artifactid => "apache-cassandra"
      }
      get  "/getUrl?repo=" + artifact[:repo] + "&groupid=" + artifact[:groupid] + "&artifactid=" + artifact[:artifactid]
      last_response.should be_ok
    end
    it "get url with version set (get request)" do
      artifact = {
      :repo => "http://repo1.maven.org/maven2", 
      :groupid => "org.apache.cassandra",
      :artifactid => "apache-cassandra",
      :version => "0.7.7"
      }
      get  "/getUrl?repo=" + artifact[:repo] + "&groupid=" + artifact[:groupid] + "&artifactid=" + artifact[:artifactid] + "&version=" + artifact[:version]
      last_response.should be_ok
      last_response.body.should match "0.7.7"
    end
  end
  
end
