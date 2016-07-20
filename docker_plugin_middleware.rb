
require 'sinatra'
require 'json'

module DockerPlugins
  VOLUME_CMDS = Set['Create','Remove','Mount','Path','Unmount','Get','List']

  def self.new_app
    Sinatra.new do

      # EXERCISE: Validate that Accept: header contains something we understand.

      post '/Plugin.Activate' do
        implements = []
        implements << "VolumeDriver"  if settings.volumedriver
        implements << "NetworkDriver" if settings.networkdriver
        { "Implements" => implements }.to_json
      end
    
      post '/VolumeDriver.:cmd' do |cmd|
        puts cmd
        cmd = cmd.to_s.downcase.to_sym
        args = JSON.parse(request.body.read)
        puts args.inspect
        
        if settings.volumedriver && settings.volumedriver.respond_to?(cmd)
          settings.volumedriver.send(cmd,args["Name"]).to_json
        else
          { "Err" => "Not implemented: #{cmd.to_s}"}.to_json
      end
      end
    
      # EXERCISE:
      # Implement NetworkDriver API
      
      
      # For debugging only.
      not_found do
        p params
        p request
      end
    
    end
  end
end

