### Knife Diff Plugin

This plugin checks the remote server and local chef cookbook repository for differences.


### Samples

	$ knife diff cookbooks
	Local orphan cookbooks:

	Remote orphan cookbooks:
	yum-repo


	$ knife diff cookbook apache2
	apache2 cookbook files out of sync:
	mod_mime.rb
	metadata.rb


	$ knife diff cookbook --all
	apache2 cookbook files out of sync:
	mod_mime.rb
	metadata.rb

	apps cookbook files out of sync:
	metadata.json