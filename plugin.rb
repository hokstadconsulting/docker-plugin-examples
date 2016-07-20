
require 'bundler/setup'
require_relative 'docker_plugin_middleware'
require 'json'
require 'fileutils'

class TestVolumePlugin

  def initialize path="./images", mountpath = "./mounts"
    FileUtils.mkdir_p(path)
    FileUtils.mkdir_p(mountpath)
    @path = path
    @mountpath = mountpath
  end

  ## Utility methods

  def image_path(name)
    File.expand_path(File.join(@path,name))
  end

  def volume_exists(name)
    File.exists?(image_path(name))
  end

  def mount_path(name)
    File.expand_path(File.join(@mountpath, name))
  end

  def mounted_path(name)
    path = mount_path(name)
    return File.exists?(path) ? path : nil
  end

  def create_volume(name)
    path = image_path(name)
    ## FIXME: Error checking:
    p system("dd","if=/dev/zero","of=#{path}","bs=1M","count=128")
    p system("mkfs.ext4","-F",path)
  end

  def mount_volume(name, path)
    img = image_path(name)
      
    # FIXME: Error check
    p system("mount","-o","loop", img,path).inspect
  end

  def unmount_volume(name,path)
    # FIXME: Error checks
    STDERR.puts system("umount",path).inspect
  end

  def remove_volume(name)
    p File.unlink(image_path(name))
  end

  ## Docker Volume plugin API

  # We don't need any special prep, so hold off on creation until Mount
  def create name
    return {"Err" => "Volume #{name} already exists"} if volume_exists?(name)
    create_volume(name)
    {}
  end

  def remove name
    return {"Err" => "Volume is mounted. Unmount first"} if mounted_path(name)
    begin
      remove_volume(name)
    rescue
      {"Err" => "Error while unlinking volume"}
    end
    {}
  end

  def mount name
    return {"Err" => "Already mounted"} if mounted_path(name)
    return {"Err" => "No such volume"}  if !volume_exists(name)
    mpath = mount_path(name)
    return {"Err" => "Unable to create mount point #{mpath}"} if !FileUtils.mkdir_p(mpath)

    mount_volume(name, mpath)
    path(name)

  rescue Exception => e
    {"Err" => "Exception: #{e.message} / #{e.backtrace.inspect}"}
  end

  def path name
    if path = mounted_path(name)
      {"MountPoint" => path}
    else
      {"Err" => "Volume is not mounted"}
    end
  end

  def unmount name
    if path = mounted_path(name)
      unmount_volume(name,path)
      STDERR.puts FileUtils.rmdir(path).inspect
      {}
    else
      {"Err" => "Volume does not exist or is not mounted"}
    end
  end


  def get name
    return {"Err" => "Volume does not exists"} if !volume_exists(name)

    ret = {
      "Volume" => {
        "Name" => name,
      }
    }
    ret["MountPoint"] ||= mounted_path(name)

    ret
  end

  def list args
    {"Err" => "List failed"}
  end
end

app = DockerPlugins.new_app
app.set :volumedriver, TestVolumePlugin.new
app.set :networkdriver, nil
#app.set :networkdriver, TestNetworkPlugin.new
app.run!

