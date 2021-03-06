### Knife Diff Plugin

This plugin checks the remote server and local chef cookbook repository for differences.

Works with:
* cookbooks
* databags

### Cookbook samples

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

### Databag Samples

	$ knife diff databags
	Local orphan databags:

	Remote orphan databags:
	
	$ knife diff databag items apps
	apps local orphan databag items:

	apps remote orphan databag items:
	
	$ knife diff databag items --all
	apps local orphan databag items:

	apps remote orphan databag items:

	git local orphan databag items:

	git remote orphan databag items:

	$ knife diff databag --all
	apps databag items out of sync:

	jenkins databag items out of sync:
	jobs

	nagios databag items out of sync:
	
	$ knife diff databag jenkins
	jenkins databag items out of sync:
	jobs

### Find Samples

	$ knife find local erb 

	apache2-0.99.3:
	* templates/default/security.erb
	* templates/default/mods/negotiation.conf.erb
	* templates/default/mod_auth_openid.rb.erb

	$ knife find remote sv

	apache2-0.99.3:
	* recipes/mod_dav_svn.rb

	apps-0.1.0:
	* templates/default/sv-app-log-run.erb
	* templates/default/sv-app-run.erb

	