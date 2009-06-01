#!/usr/bin/python2.4
#
# Copyright 2009 Google Inc. All Rights Reserved.

"""Module defines the ModuleTestRunnerClass."""


__author__ = 'davidbyttow@google.com (David Byttow)'


require 'test/unit'


class ModuleTestRunner
  """Responsible for executing all test cases in a list of modules."""

  def initialize(module_list=None, module_test_settings=None)
    self.modules = module_list or []
    self.settings = module_test_settings or {}
  end

  def RunAllTests
    """Executes all tests present in the list of modules."""
    runner = unittest.TextTestRunner()
    for module_name in @modules
      for setting, value in self.settings.iteritems()
        begin
          setattr(module_name, setting, value)
        rescue AttributeError:
          print '\nError running ' + str(setting)
        end
      end
      print '\nRunning all tests in module', module_name.__name__
      runner.run(unittest.defaultTestLoader.loadTestsFromModule(module_name))
    end
  end
end
