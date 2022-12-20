#!/usr/bin/python
#
# -*- coding: utf-8 -*-
#
import getopt
import os
import sys
import re

from subprocess import call

def Usage():
    """Show usage information"""
    print
    print "Usage: python freight-add-many.py [options]"
    print
    print "Options:"
    print "  -p pattern     | --pattern=pattern     Filename pattern to match"
    print "  -c config      | --config=config       Freight configuration file to use"
    print "  -d directory   | --directory=directory Directory with the packages, defaults to \".\""
    print "  -s             | --simulate            Only show the command that would run"
    print "  -h             | --help                Show this help"
    print
    print "Examples:"
    print
    print "  ./freight-add-many.py -p 2.3.12 -c /etc/freight-openvpn_stable.conf -d ~/output"
    print "  ./freight-add-many.py -p 2.4-alpha2 -c /etc/freight-openvpn_testing.conf -d ~/output"
    print
    print "If freight complains about GPG an ioctls you've likely hit freight bug #72. In that case"
    print "run this command before running freight-add-many.py:"
    print
    print "  export GPG_TTY=$(tty)"
    print

    sys.exit(1)

def main():
    """Main program"""

    # Default values
    pattern=None
    config=None
    directory="."
    simulate=False

    # Parse command-line arguments
    try:
        opts, args = getopt.getopt(sys.argv[1:], 'p:c:d:sh', [ 'pattern=', 'config=', 'directory=', 'simulate', 'help' ])

        for o, a in opts:
            if o in ('-p', '--pattern'):
                pattern = a
            if o in ('-c', '--config'): 
                config = a
            if o in ('-d', '--directory'):
                directory = a
            if o in ('-s', '--simulate'):
                simulate=True
            if o in ('-h','--help'):
                Usage()

    except getopt.GetoptError:
        Usage()

    if not pattern:
        Usage()
    if not config:
        Usage()

    try:
        f = open(config, 'r')
        print "NOTICE: freight config: %s" % (config)
        f.close()
    except:
        print "ERROR: failed to openvpn config %s" % (config)
        sys.exit(1)

    if os.path.isdir(directory):
        print "NOTICE: packages in %s" % (directory)
    else:
        print "ERROR: %s is not a directory!" % (directory)
        sys.exit(1)

    # Main loop: add packages to the repository
    regexp = re.compile('[a-zA-Z]+')
    for package in os.listdir(directory):
        if re.search(pattern, package):
            lsbdistcodename = re.findall(regexp, package)[-3]
            source=os.path.join(directory, package)
            target="apt/%s" % (lsbdistcodename)

            freight_add_call = ['freight-add','-c', config, source, target]

            if simulate:
                print "NOTICE: would run %s" % (' '.join(freight_add_call))
            else:
                call(freight_add_call)

    # Update freight cache
    freight_cache_call=['freight-cache', '-c', config]
    freight_cache_call_str=' '.join(freight_cache_call)

    if simulate:
        print "NOTICE: would run %s" % (freight_cache_call_str)
    else:
        print "NOTICE: running %s" % (freight_cache_call_str)
        call(freight_cache_call)

    sys.exit(0)

if __name__ == '__main__':
    main()
