#!/usr/bin/env python
"""
This script extracts lsl scripts and notecards from an exported SL object and
moves them into another folder, with nice names.  It also strips
OpenCollar-style version numbers if found.


It takes two arguments: 
    1 - path to the export xml file
    2 - (Optional) path to the 'lsl' folder within the repo.  If this is not
    provided, then the script will look for an 'lsl' folder within the same
    directory where the script is located.

Example:
    python xml2lsl.py ~/some_exported_object.xml

Example with passing in a destination:
    python xml2lsl.py ~/some_exported_object.xml ~/some_exported_scripts

"""
import sys
import os
import shutil
import re
from lxml import etree

def map_to_dict(mapnode):
    """Given a 'map' node from an inventory item in an exported xml file,
    return a dictionary with the keys and values."""
    kvs = [c.text for c in mapnode.getchildren()]
    return dict(zip(kvs[::2], kvs[1::2]))

def copy_from_assets(item, asset_dir, proj_dir):
    """Given an item dict, an export asset directory, and a project directory,
    move the item from asset_dir to proj_dir.  Use item['name'] as new
    filename.""" 
    script_name = item['name']
    if item['type'] == 'lsltext':
        # strip off the version part of the name
        script_name = re.sub(' - \d\.\d{3}', '', script_name)
        # append .lsl if necessary
        if not script_name.endswith('.lsl'):
            script_name += '.lsl'
    src = os.path.join(asset_dir, '.'.join([item['item_id'], item['type']]))
    dest = os.path.join(proj_dir, script_name)
    try:
        shutil.copyfile(src, dest)
    except IOError, e:
        print e
    # TODO: make sure the name is safe for the filesystem

def load_info():
    """Return a dictionary with all the information needed to sync from xml to
    lsl or back."""
    try:
        xmlfile = sys.argv[1]
        # Assumes that xmlfile ends in .xml, and that there's a folder in the
        # same place named <export_name>_assets
        asset_dir = xmlfile[:-4] + '_assets'
    except IndexError:
        sys.exit(__doc__)

    try:
        proj_dir = sys.argv[2]
    except IndexError:
        here = os.path.dirname(os.path.realpath(__file__))
        proj_dir = os.path.join(here, 'lsl')

    tree = etree.parse(open(xmlfile, 'r'))

    # this node should now be an 'array' element with a series of 'map' elements in
    # it (my god xml is ugly)
    node = tree.xpath('/llsd/map/array[1]/map/array[1]/map/array[1]')[0] 
    items = [map_to_dict(c) for c in node.getchildren()]

    # we only care about scripts and notecards, so filter list down to just them.
    items = [i for i in items if i['type'] in ('lsltext', 'notecard')]
    return locals()


def main():
    info = load_info()

    # Ensure that proj_dirdir exists.
    if not os.path.exists(info['proj_dir']):
        os.mkdir(info['proj_dir'])

    for item in info['items']:
        item.update(info)
        print "Copying %(name)s to %(proj_dir)s" % item
        copy_from_assets(item, info['asset_dir'], info['proj_dir'])

if __name__ == '__main__':
    main()
