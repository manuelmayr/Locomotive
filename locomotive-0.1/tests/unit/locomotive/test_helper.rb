# add the locomotive lib directory to the load-path
dir = File.dirname(__FILE__)
$LOAD_PATH.unshift "#{dir}/../../../lib"

require 'test/unit'
require 'locomotive'
