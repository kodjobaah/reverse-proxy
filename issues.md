Even though aws allows you to maintain the original path that is sent, i.e the prefix
is not removed. terraform currently does not support that feature.
https://github.com/hashicorp/terraform-provider-aws/issues/20272
