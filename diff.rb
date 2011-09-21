#
## Author:: Joe Williams (j@boundary.com)
##
## Licensed under the Apache License, Version 2.0 (the "License");
## you may not use this file except in compliance with the License.
## You may obtain a copy of the License at
##
##     http://www.apache.org/licenses/LICENSE-2.0
##
## Unless required by applicable law or agreed to in writing, software
## distributed under the License is distributed on an "AS IS" BASIS,
## WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
## See the License for the specific language governing permissions and
## limitations under the License.
##
#

require File.expand_path('../lib/boundary_knife_plugins.rb', __FILE__)

require 'chef/knife'
require 'digest/md5'

module BoundaryKnifePlugins
  class DiffCookbooks < Chef::Knife
    include Common
    
    deps do
      require 'chef/cookbook_loader'
    end
 
    banner "knife diff cookbooks"
    
    def run
      self.config = Chef::Config.merge!(config)
      
      remote_cookbooks = build_sorted_remote_cookbook_list(rest)
      
      local_cookbooks = build_sorted_local_cookbook_list
      
      local_only = diff_lists(local_cookbooks, remote_cookbooks)
      ui.info("Local orphan cookbooks:")
      ui.info(local_only)
      
      remote_only = diff_lists(remote_cookbooks, local_cookbooks)
      ui.info("\nRemote orphan cookbooks:")
      ui.info(remote_only)
      
    end
  end
  
  class DiffCookbook < Chef::Knife
    include Common

    deps do
      require 'chef/cookbook_loader'
    end
 
    banner "knife diff cookbook COOKBOOK [options]"
    
    option :all,
      :short => "-a",
      :long => "--all",
      :description => "Compare all cookbooks (list provided by local repo), rather than just a single cookbook"
        
    def run
      self.config = Chef::Config.merge!(config)
      
      if config[:all]
        remote_cookbooks = build_sorted_local_cookbook_list
        
        remote_cookbooks.each do |cookbook|
          cookbook_compare(ui, rest, cookbook)
        end
        
      else
        unless name_args.size == 1
          ui.error("Please specify a cookbook!")
          show_usage
          exit 1
        end

        cookbook_compare(ui, rest, name_args.first)
      end
    end
  end
  
  class DiffDatabags < Chef::Knife
    include Common

    deps do
      require 'chef/data_bag'
    end
    
    banner "knife diff databags"
    
    def run
      path = "#{Chef::Config[:cookbook_path]}/../data_bags"
      
      local_dbags = get_sorted_local_databags(path)
      
      remote_dbags = Chef::DataBag.list.keys.sort
      
      ui.info("Local orphan databags:")
      ui.info(local_dbags.sort - remote_dbags)
      
      ui.info("\nRemote orphan databags:")
      ui.info(remote_dbags - local_dbags.sort)
    end
    
  end
  
  class DiffDatabagItems < Chef::Knife
    include Common

    deps do
      require 'chef/data_bag'
    end
    
    banner "knife diff databag items DATABAG [options]"
    
    option :all,
      :short => "-a",
      :long => "--all",
      :description => "Compare all data bags (list provided by local repo), rather than just a single cookbook"
    
    def run
      path = "#{Chef::Config[:cookbook_path]}/../data_bags"
            
      if config[:all]
        local_dbags = get_sorted_local_databags(path)
            
        local_dbags.each do |databag|
          compare_databag_item_lists(ui, path, databag)
        end        
      else
        compare_databag_item_lists(ui, path, name_args.first)
      end
    end
    
  end
  
  class DiffDatabag < Chef::Knife
    include Common

    deps do
      require 'chef/data_bag'
    end
    
    banner "knife diff databag DATABAG [options]"
    
    option :all,
      :short => "-a",
      :long => "--all",
      :description => "Compare all data bags (list provided by local repo), rather than just a single cookbook"
    
    def run
      path = "#{Chef::Config[:cookbook_path]}/../data_bags"
      
      if config[:all]
        remote_dbags = Chef::DataBag.list.keys
        
        remote_dbags.each do |dbag|
          compare_databag_items(ui, path, dbag)
        end
        
      else
        compare_databag_items(ui, path, name_args.first)
      end
    end
    
  end

  class DiffRole < Chef::Knife
    
    deps do 
      require 'chef/role'
      require 'chef/knife/core/object_loader'
      require 'chef/json_compat'
    end
    
    option :all,
      :short => "-a",
      :long => "--all",
      :description => "Compare all roles, Uses remote list to determine set. Only supports local .json roles for now"

    banner "knife diff role ROLE"

    def loader
      @loader ||= Chef::Knife::Core::ObjectLoader.new(Chef::Role, ui)
    end

    def run
      @path = "#{Chef::Config[:cookbook_path].first}/../roles"
      @local_roles  = local_roles
      @remote_roles = format_list_for_display(Chef::Role.list)
  
      if config[:all]
        @remote_roles.each do |role|
          compare_role(role)
        end
      else 
        compare_role(name_args.first)
      end
    end
    

    # md5 and cmp remote to local
    def compare_role(role)
      if @local_roles.has_key?(role)
        remote_role = Chef::Role.load(role)
        remote_sum = digest(Chef::Role.load(role).to_json)
        local_sum  = digest(loader.load_from("roles", @local_roles[role]).to_json)
        ui.info "#{role} is out of sync" if local_sum != remote_sum
      else
        ui.info "#{role} is on server, but not found in local list"
      end        
    end
   
    # return an array of rolefile names
    # supports 2 levels of subdirs
    def local_files
      files = []
      %w/json rb/.each do |ext|
        files << Dir["#{@path}/*.#{ext}", "#{@path}/*/*.#{ext}", "#{@path}/*/*/*.#{ext}"] 
      end
      files.flatten.sort.uniq
    end  

    # hash of local role names as keys with path as values
    def local_roles
      file_map = {}
      local_files.map {|file| file_map[ File.basename(file, File.extname(file)) ] = file }
      file_map
    end
 
    # generate an md5sum 
    def digest(data)
      Digest::MD5.hexdigest(data)
    end 
  end
  
end