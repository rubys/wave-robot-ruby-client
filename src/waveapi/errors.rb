#!/usr/bin/python2.4
#
# Copyright 2009 Google Inc. All Rights Reserved.

"""Contains various API-specific exception classes.

This module contains various specific exception classes that are raised by
the library back to the client.
"""

__author__ = 'davidbyttow@google.com (David Byttow)'


class Error(Exception):
  """Base library error type."""
