# Author:: Salvatore Poliandro III (sal@opsitters.com)
# Cookbook Name:: opsit_libs
# Library:: log
#
# Copyright 2015, OpSitters
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

  def opsit_exit(msg, options = {})
    log_errors = options.fetch(:log_errors, true)

    if log_errors then
      opsit_error(msg)
    end
    raise msg
  end

  def opsit_debug(msg, prefix="")
    # grab the caller's name (between quotes `') off the top of stack
    method = caller[0][/`([^']*)'/, 1]
    Chef::Log.debug("OPSITTERS: #{prefix}#{method}(): #{msg}")
  end

  def opsit_log(msg)
    # grab the caller's name (between quotes `') off the top of stack
    method = caller[0][/`([^']*)'/, 1]
    Chef::Log.info("OPSITTERS: #{method}(): #{msg}")
  end

  def opsit_warn(msg)
    # grab the caller's name (between quotes `') off the top of stack
    method = caller[0][/`([^']*)'/, 1]
    Chef::Log.warn("OPSITTERS: #{method}(): #{msg}")
  end

  def opsit_error(msg)
    # grab the caller's name (between quotes `') off the top of stack
    method = caller[0][/`([^']*)'/, 1]
    Chef::Log.info("OPSITTERS: #{method}(): #{msg}")
  end



end #end module

class Chef::Recipe
  include OPSITTERS
end

class Chef::Provider
  include OPSITTERS
end
