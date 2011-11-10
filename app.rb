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
    artifact = Artifact.from_params(params)
    artifact.unique_version
  end

  post '/getUrl' do
    artifact = Artifact.from_json(params['json'])
    artifact.artifact_url
    
  end

  get '/getUrl' do
    artifact = Artifact.from_params(params)
    client = HTTPClient.new
    md5sum = client.get(artifact.artifact_url+".md5").body
    response.headers["md5sum"] = md5sum
    artifact.artifact_url
  end
  
  get '/getArtifact' do
    artifact = Artifact.from_params(params)
    client = HTTPClient.new
    md5sum = client.get(artifact.artifact_url+".md5").body
    response.headers["md5sum"] = md5sum
    redirect artifact.artifact_url

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
    data['version'] ? artifact.version = data['version'] : artifact.version = artifact.developmentversion

    artifact
  end

  def self.from_params(params)
    artifact = Artifact.new()
    artifact.groupid=params['groupid']
    artifact.artifactid=params['artifactid']
    artifact.repo=params['repo']
    artifact.validate_version(params['version']) ? artifact.version = params[:version] : artifact.version = artifact.developmentversion

    artifact
  end 
  
  def validate_version(version)
    if version 
      if version == "" #empty form 
        return false
      else
        return true
      end
    end
    return false

  end
  
  def urlpart
    repo + "/" + groupid.gsub('.','/') + "/" + artifactid.gsub('.','/') + "/"
  end
  
  def artifact_url
    urlpart + developmentversion + "/" + artifactid+ "-"+ unique_version  + file_extension + "\n"
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
