#!/usr/bin/env python
"""
This is the mirror image of xml2lsl.py.  This script reads an xml file
produced by Phoenix object export, loops over the contents, and updates the
export's assets folder with files from the Git repo (or other folder that you
specify.

It takes two arguments: 
    1 - path to the export xml file
    2 - (Optional) path to the 'lsl' folder within the repo.  If this is not
    provided, then the script will look for an 'lsl' folder within the same
    directory where the script is located.

Example:
    python lsl2xml.py ~/some_exported_object.xml

Example with passing in a destination:
    python lsl2xml.py ~/some_exported_object.xml ~/some_exported_scripts

Re-uses some functions from xml2lsl, so that should be on the PYTHONPATH or
in the same dir as this script.
"""

import os
import re
import shutil

from xml2lsl import load_info

def copy_to_assets(item, asset_dir, proj_dir):
    """Given an item dict, an export asset directory, and a project directory,
    move the item from proj_dir to asset_dir.  Use <item_id>.<type> as new
    filename.""" 
    # strip off version, and add .lsl, to get the project script name
    script_name = item['name']
    if item['type'] == 'lsltext':
        # strip off the version part of the name
        script_name = re.sub(' - \d\.\d{3}', '', script_name)
        if not script_name.endswith('.lsl'):
            script_name += '.lsl'
    # Now build destination name from the item_id
    src = os.path.join(proj_dir, script_name)
    dest = os.path.join(asset_dir, '.'.join([item['item_id'], item['type']]))
    try:
        print "Copying %(src)s to %(dest)s" % locals()
        shutil.copyfile(src, dest)
    except IOError, e:
        print e

def main():
    info = load_info()

    # Ensure that destdir exists.
    if not os.path.exists(info['asset_dir']):
        os.mkdir(info['asset_dir'])

    for item in info['items']:
        item.update(info)
        copy_to_assets(item, info['asset_dir'], info['proj_dir'])

if __name__ == '__main__':
    main()
