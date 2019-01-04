''' A simple utility for cleaning up temp files (png images) written on the server'''
from __future__ import print_function
import os
import time

# This will delete any files in the temp dir of this age or older:        
DELETE_THRESHOLD_HOURS = 12

for root, subdirs, files in os.walk("../temp"):

    for f in files:
        fpath = "/".join((root, f))
        file_mod_time = os.stat(fpath).st_mtime
        hours_old = (time.time() - file_mod_time)/(60*60)

        if hours_old >= DELETE_THRESHOLD_HOURS:
            os.remove(fpath)
