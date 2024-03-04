# Namecheap-Linux-Dynamic-DNS

https://github.com/wilsonnkwan

wilsonnkwan originally created a script for sharing to do auto update of dynamic DNS for Linux and Windows.


This clone merges thorrak pull request: Change DNS lookup to account for ipv6 issue 

There was an issue with the original script, where when looking up against Google's DNS servers It would consistently get an ipv6 address back which is incompatible with the Dynamic DNS record being updated. To correct for this, The lookup was updated to instead check against opendns's servers.

Additionally, this PR changes the mode of linuxdyndns.sh from 644 to 755.
