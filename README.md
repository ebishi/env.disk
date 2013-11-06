env.disk
========

A portable shell environment, to live on a USB stick.

This script unpacks SSH & GPG config files to a ramdisk, & loads private keys into the agent. It expects to find

	./env/gpg.tpg - gpg config & private keys
	./env/public_gpg - puglic gpg keys to add to keychain
	./env/ssh.tpg - ssh config & keys
	
TODO:

* if ramdisk already exists, just rename, don't bother trying to eject.
* add known_hosts to ssh.tpg
