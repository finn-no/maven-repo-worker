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
    it "getUrl (groupid,artifactid)" do
       artifact = {
      :groupid => "org.apache.tiles",
      :artifactid => "tiles-jsp"
      }
      post  '/getUrl', 'json' => artifact.to_json
      last_response.should be_ok
      last_response.body.should match "snapshot"
      get  "/getUrl?groupid=" + artifact[:groupid] + "&artifactid=" + artifact[:artifactid]
      last_response.should be_ok
    end
    it "getUrl (groupid,artifactid,version)" do
       artifact = {
      :groupid => "org.apache.tiles",
      :artifactid => "tiles-jsp",
      :version => "2.2.2"
      }
      post  '/getUrl', 'json' => artifact.to_json
      last_response.should be_ok
      last_response.body.should match "repo1.maven.org"
      get  "/getUrl?groupid=" + artifact[:groupid] + "&artifactid=" + artifact[:artifactid] + "&version=" + artifact[:version]
      last_response.should be_ok
    end
    it "getUrl (repo,groupid,artifactid)" do
      artifact = {
      :repo => "http://repo1.maven.org/maven2/", 
      :groupid => "org.apache.cassandra",
      :artifactid => "apache-cassandra"
      }
      post  '/getUrl', 'json' => artifact.to_json
      last_response.should be_ok
      get  "/getUrl?repo=" + artifact[:repo] + "&groupid=" + artifact[:groupid] + "&artifactid=" + artifact[:artifactid]
      last_response.should be_ok
    end
    it "getUrl (repo,groupid,artifactid,version)" do
      artifact = {
      :repo => "http://repo1.maven.org/maven2/", 
      :groupid => "org.apache.cassandra",
      :artifactid => "apache-cassandra",
      :version => "0.7.6"
      }
      post  '/getUrl', 'json' => artifact.to_json
      last_response.should be_ok
      last_response.body.should match "0.7.6"

      get  "/getUrl?repo=" + artifact[:repo] + "&groupid=" + artifact[:groupid] + "&artifactid=" + artifact[:artifactid] + "&version=" + artifact[:version]
      last_response.should be_ok
      last_response.body.should match "0.7.6"

   end
    it "getUrl (repo,groupid,artifactid,type)" do
      artifact = {
      :repo => "http://repo1.maven.org/maven2", 
      :groupid => "org.apache.cassandra",
      :artifactid => "cassandra-javautils",
      :type => "jar"
      }
      get  "/getUrl?repo=" + artifact[:repo] + "&groupid=" + artifact[:groupid] + "&artifactid=" + artifact[:artifactid] + "&type=" + artifact[:type]
      last_response.should be_ok
      last_response.body.should match ".jar"
      last_response.header["groupid"].should match "org.apache.cassandra"
      post '/getUrl', 'json' =>  artifact.to_json
      last_response.should be_ok
      last_response.body.should match ".jar"
 
    end
  end
  
end
