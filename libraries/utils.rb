# Author:: Salvatore Poliandro III (sal@opsitters.com)
# Cookbook Name:: opsit_libs
# Library:: utils
#
# Copyright 2015, OpSitters
# Copyright 2012-2013, Rackspace US, Inc. (osops-utils cookbook)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#


module OPSITTERS

  # This takes a node hash and an attribute in string format such as
  # 'opsit.internal_ip' and returns its value
  def get_node_attrib(nodeish, attribute)
    attrib_value = nodeish
    path_ary = attribute.split('.')
    path_ary.each do |k|
      if attrib_value && attrib_value.key?(k)
        attrib_value = attrib_value[k]
      elsif attrib_value && attrib_value.respond_to?(k)
        attrib_value = attrib_value.send(k)
      else
        attrib_value = nil
      end
    end
    attrib_value

end #end module

class Chef::Recipe
  include OPSITTERS
end

class Chef::Provider
  include OPSITTERS
end
