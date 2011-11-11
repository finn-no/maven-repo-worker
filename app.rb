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
    @value = artifact.unique_version
    erb :response
  end
  
  get '/getCurrentVersion' do
    artifact = Artifact.from_params(params)
    @value = artifact.unique_version
    erb :response
  end

  post '/getUrl' do
    artifact = Artifact.from_json(params['json'])
    @value = artifact.artifact_url
    erb :response
  end

  get '/getUrl' do
    artifact = Artifact.from_params(params)
    client = HTTPClient.new
    artifact.headers response.headers
    @value = artifact.artifact_url
    erb :response
  end
  
  get '/getArtifact' do
    artifact = Artifact.from_params(params)
    artifact.headers response.headers
    redirect artifact.artifact_url

  end
end

class Artifact
  attr_accessor :repo, :groupid, :artifactid, :version, :extension

  def self.from_json(json)
    artifact = Artifact.new()
    data = JSON.parse(json)
    artifact.groupid = data['groupid']
    artifact.artifactid = data['artifactid']
    artifact.repo = artifact.set_repo data
    data['version'] ? artifact.version = data['version'] : artifact.version = artifact.developmentversion
    if data['type'] 
      artifact.extension = data['type'] 
    end

    artifact
  end

  def self.from_params(params)
    artifact = Artifact.new()
    artifact.groupid=params['groupid']
    artifact.artifactid=params['artifactid']
    artifact.repo = artifact.set_repo params
    if params['type'] 
      artifact.extension = params['type'] 
    end
    artifact.validate_version(params['version']) ? artifact.version = params[:version] : artifact.version = artifact.developmentversion

    artifact
  end 

  def set_repo(data)
    data['repo'] ? data['repo'] : find_repo(data)
  end 

  def find_repo(data)
    if data['version']
      /SNAPSHOT/.match(data['version']) ? set_snapshot_repo : set_release_repo
    else
      set_snapshot_repo 
    end
  end
  
  def set_snapshot_repo
    ENV['SNAPSHOT_REPO'] ? ENV['SNAPSHOT_REPO'] : "http://repository.apache.org/snapshots/" 
  end

  def set_release_repo
    ENV['RELEASE_REPO'] ? ENV['RELEASE_REPO'] : "http://repo1.maven.org/maven2"
  end 

  def headers(headers)
    client = HTTPClient.new
    headers['version'] = unique_version
    headers['groupid'] = groupid
    headers['artifactid'] = artifactid
    headers['md5sum'] = client.get(artifact_url+".md5").body
    headers['type'] = file_extension
    headers
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
    urlpart + developmentversion + "/" + artifactid+ "-"+ unique_version  + "." + file_extension 
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
    @extension ||= packaging == "maven-plugin" ? "jar" : packaging
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
