# INFRA SETUP scaffold

This scaffold is really a digital ocean infra-template.

You'll need to edit the files to fit the cloud provider you want.

The main goals are to:
- provision infrastructure that are within the same subnet and/or are visible to eath other over a local/private network.
- Write an appropriate command(see [config.yml sample](config.yml)) that can extract the IPs into a comma separated string.

