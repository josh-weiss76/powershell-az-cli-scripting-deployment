# TODO: set variables
$studentName = "josh"
$rgName = "$studentName-ps-az-script-rg"
$vmName = "$studentName-ps-az-script-vm"
$vmSize = "Standard_B2s"
$vmImage = "$(az vm image list --query "[? contains(urn, 'Ubuntu')] | [0].urn")"
$vmAdminUsername = "student"
$vmAdminPassword = "LaunchCode-@zure1"
$kvName = "$studentName-lc0820-ps-kv"
$kvSecretName = "ConnectionStrings--Default"
$kvSecretValue = "server=localhost;port=3306;database=coding_events;user=coding_events;password=launchcode"

# TODO: provision RG

az configure --defaults location=eastus
az group create -n "$rgName"
az configure --default group="$rgName"

# TODO: provision VM

az vm create -n "$vmName" --size "$vmSize" --image "$vmImage" --admin-username "$vmAdminUsername" --assign-identity --generate-ssh-keys

# TODO: capture the VM systemAssignedIdentity

$vmObjectId = "$(az vm show -g $rgName -n $vmName --query "identity.principalId")"

# TODO: open vm port 443

az vm open-port -g "$rgName" -n "$vmName" --port 443

# provision KV

az keyvault create -n "$kvName" --enable-soft-delete false --enabled-for-deployment true

# TODO: create KV secret (database connection string)

az keyvault secret set --vault-name "$kvName" -n "$kvSecretName" --value "$kvSecretValue"

# TODO: set KV access-policy (using the vm ``systemAssignedIdentity``)

az keyvault set-policy -n "$kvName" --object-id "$vmObjectId" --secret-permissions get list

$vmIp = az vm show -n "$vmName" -d --query ("publicIps")

az vm run-command invoke -g "$rgName" -n "$vmName" --command-id RunShellScript --scripts @vm-configuration-scripts/1configure-vm.sh

az vm run-command invoke -g "$rgName" -n "$vmName" --command-id RunShellScript --scripts @vm-configuration-scripts/2configure-ssl.sh

az vm run-command invoke -g "$rgName" -n "$vmName" --command-id RunShellScript --scripts @deliver-deploy.sh


# TODO: print VM public IP address to STDOUT or save it as a file
$vmIp
