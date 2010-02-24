# add the locomotive lib directory to the load-path
$: << "#{File.dirname(__FILE__)}/../../../lib"

def import *libs
  libs.each do |lib|
    require "#{lib}"
  end
end
