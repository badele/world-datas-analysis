#!/bin/bash

import os
import requests
from ftplib import FTP


# ftp = FTP('your-ftp-domain-or-ip')
# ftp.login('your-username','your-password')

# # Get All Files
# files = ftp.nlst()

# # Print out the files
# for file in files:
# 	print("Downloading..." + file)
# 	ftp.retrbinary("RETR " + file ,open("download/to/your/directory/" + file, 'wb').write)

# ftp.close()

# end = datetime.now()
# diff = end - start
# print('All files downloaded for ' + str(diff.seconds) + 's')`



def downloadHttpFile(url,filename,messagz=None):
    if not os.path.exists(filename):
        if messagz is not None:
            print(messagz)
        
        r = requests.get(url, allow_redirects=True)
        with open(filename, 'wb') as f:
            f.write(r.content)

def downloadFtpFile(domaine,ftpfile,filename,username=None,password=None):
    if not os.path.exists(filename):
        ftp = FTP(domaine)
        ftp.login(username,password)

        with open(filename, 'wb') as f:
            ftp.retrbinary(f"RETR {ftpfile}" ,f.write)
