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
 
module BoundaryKnifePlugins
  class FindRemote < Chef::Knife
    include Common
  
    deps do
      require 'chef/cookbook_loader'
    end
 
    banner "knife find remote PATHTEXT"
    
    def run
      self.config = Chef::Config.merge!(config)
      
      unless name_args.size == 1
        ui.error("Please specify some text to search for!")
        show_usage
        exit 1
      end
            
      remote_cookbooks = build_sorted_remote_cookbook_list(rest)
      
      remote_cookbooks.each do |cookbook|
        manifest = get_cookbook(rest, cookbook).manifest
        find_files(ui, manifest, name_args.first)
      end      
    end
    
  end
  
  class FindLocal < Chef::Knife
    include Common

    deps do
      require 'chef/cookbook_loader'
    end
 
    banner "knife find local PATHTEXT"
    
    def run
      self.config = Chef::Config.merge!(config)
      
      unless name_args.size == 1
        ui.error("Please specify some text to search for!")
        show_usage
        exit 1
      end
            
      local_cookbooks = build_sorted_local_cookbook_list
      
      local_cookbooks.each do |cookbook|
        manifest = get_cookbook(rest, cookbook).manifest
        find_files(ui, manifest, name_args.first)
      end
    end
    
  end
  
end
