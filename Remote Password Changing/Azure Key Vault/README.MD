$clientid = $args[0]
$clientSecret = $args[1]
$tenantID = $args[2]

you can use the new built-in in template - Azure Application Registration

And then add additional field - "Vault Name" to any template that you are going to use to populate this - $AKVaultName = $args[3]
Azure Application Registration secret is going to be an associated secret