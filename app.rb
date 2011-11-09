require 'rubygems'
require 'bundler/setup'
require 'sinatra/base'
require 'json'
require 'httpclient'
require 'nokogiri'


class MavenService < Sinatra::Base
  
  get '/' do
  erb :index
  end

  post '/getCurrentVersion' do
    artifact = Artifact.from_json(params['json'])
    artifact.unique_version
  end
  
  get '/getCurrentVersion' do
    artifact = Artifact.new()
    artifact.groupid=params['groupid']
    artifact.artifactid=params['artifactid']
    artifact.repo=params['repo']
    artifact.unique_version
  end

  post '/getUrl' do
    artifact = Artifact.from_json(params['json'])
    developmentversion = artifact.developmentversion
    artifact.urlpart + developmentversion + "/" + artifact.artifactid+ "-"+ artifact.unique_version  + artifact.file_extension
    
  end

  get '/getUrl' do
    artifact = Artifact.new()
    artifact.groupid=params['groupid']
    artifact.artifactid=params['artifactid']
    artifact.repo=params['repo']
    developmentversion = artifact.developmentversion
    artifacturl = artifact.urlpart + developmentversion + "/" + artifact.artifactid+ "-"+ artifact.unique_version  + artifact.file_extension
    client = HTTPClient.new
    md5sum = client.get(artifacturl+".md5").body
    response.headers["md5sum"] = md5sum
    artifacturl
  end
  
  get '/getArtifact' do
    artifact = Artifact.new()
    artifact.groupid=params['groupid']
    artifact.artifactid=params['artifactid']
    artifact.repo=params['repo']
    developmentversion = artifact.developmentversion
    artifacturl = artifact.urlpart + developmentversion + "/" + artifact.artifactid+ "-"+ artifact.unique_version  + artifact.file_extension
    client = HTTPClient.new
    md5sum = client.get(artifacturl+".md5").body
    response.headers["md5sum"] = md5sum
    redirect artifacturl

  end



end

class Artifact
  attr_accessor :repo, :groupid, :artifactid, :version, :extension
  
  def self.from_json(json)
    artifact = Artifact.new()
    data = JSON.parse(json)
    artifact.repo = data['repo']
    artifact.groupid = data['groupid']
    artifact.artifactid = data['artifactid']
    artifact
  end 
  
  def urlpart
    repo + "/" + groupid.gsub('.','/') + "/" + artifactid.gsub('.','/') + "/"
  end
  
  def unique_version
    developmentversion.gsub("SNAPSHOT", meta_data(urlpart + developmentversion).unique_version)
  end
  
  def developmentversion
    @version ||= meta_data(urlpart).latest_version
  end
  
  def packaging
    url = urlpart + developmentversion + "/" + artifactid+ "-"+   unique_version + ".pom"     
    pom(url).packaging
  end
  
  def file_extension
    @extension ||= packaging == "maven-plugin" ? ".jar" : "."+packaging
  end
  
  def pom(url)
    client = HTTPClient.new
    xml = client.get(url).body
    Pom.new(Nokogiri.XML(xml))
  end
  
  def meta_data(urlpart)
    metadataurl = urlpart + "/maven-metadata.xml"
    client = HTTPClient.new
    xml = client.get(metadataurl).body
    MetaData.new(Nokogiri.XML(xml))
  end

end

class MetaData
  def initialize(doc)
    @doc = doc
  end
  
  def latest_version
    @doc.xpath("//versioning/latest").text
  end
  
  def unique_version
    #puts @doc
    @doc.xpath("//versioning/snapshot/timestamp").text + "-" + @doc.xpath("//versioning/snapshot/buildNumber").text
  end
end

class Pom
  def initialize(doc)
    @doc = doc
  end
  
  def packaging
    @doc.xpath("//xmlns:packaging").text
  end
end
