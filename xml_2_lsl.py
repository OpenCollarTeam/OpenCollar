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
    python xml_to_lsl.py ~/some_exported_object.xml

Example with passing in a destination:
    python xml_to_lsl.py ~/some_exported_object.xml ~/some_exported_scripts

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

def move_item(item, srcdir, destdir):
    """Given an item dict, a source directory, and a destination directory, move
    the item from srcdir to destdir.  Use item['name'] as new filename.""" 
    new_name = item['name']
    if item['type'] == 'lsltext':
        # strip off the version part of the name
        new_name = re.sub(' - \d\.\d{3}', '', new_name)
        new_name += '.lsl'
    src = os.path.join(srcdir, '.'.join([item['item_id'], item['type']]))
    dest = os.path.join(destdir, new_name)
    try:
        shutil.copyfile(src, dest)
    except IOError, e:
        print e
    # TODO: make sure the name is safe for the filesystem

def main():
    try:
        xmlfile = sys.argv[1]
        # Assumes that xmlfile ends in .xml, and that there's a folder in the
        # same place named <export_name>_assets
        asset_dir = xmlfile[:-4] + '_assets'
    except IndexError:
        sys.exit(__doc__)

    try:
        dest = sys.argv[2]
    except IndexError:
        here = os.path.dirname(os.path.realpath(__file__))
        dest = os.path.join(here, 'lsl')

    tree = etree.parse(open(xmlfile, 'r'))

    # this node should now be an 'array' element with a series of 'map' elements in
    # it (my god xml is ugly)
    node = tree.xpath('/llsd/map/array[1]/map/array[1]/map/array[1]')[0] 
    items = [map_to_dict(c) for c in node.getchildren()]

    # we only care about scripts and notecards, so filter list down to just them.
    items = [i for i in items if i['type'] in ('lsltext', 'notecard')]


    # Ensure that destdir exists.
    if not os.path.exists(dest):
        os.mkdir(dest)

    for item in items:
        print "Copying", item['name']
        move_item(item, asset_dir, dest)

if __name__ == '__main__':
    main()
