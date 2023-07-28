ssm
curl “https://s3.amazonaws.com/session-manager-downloads/plugin/latest/mac/session-manager-plugin.pkg” -o “session-manager-plugin.pkg”
sudo installer -pkg session-manager-plugin.pkg -target /
sudo ln -s /usr/local/sessionmanagerplugin/bin/session-manager-plugin /usr/local/bin/session-manager-plugin

Then to connect:

aws ecs execute-command --profile afriex      --region eu-west-2     --cluster webhook-acceptance-test-cluster-dev     --task 21b89b7de2b649bf82b7bf1801dd5a3a     --container weezy-marketplace-prod-supervisor     --command "/bin/bash"   --interactive\

