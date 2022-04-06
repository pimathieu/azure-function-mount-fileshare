let "randomIdentifier=$RANDOM*$RANDOM"
resourceGroup="azure-func-dev-func-resource-group"
functionApp="azure-funcdev-function-app"
shareId="funct-share-$randomIdentifier"
share="file-share"
AZURE_STORAGE_ACCOUNT="sharestorageacct"
mountPath="/mounted-$randomIdentifier"
AZURE_STORAGE_KEY=""
az webapp config storage-account add --resource-group $resourceGroup --name $functionApp --custom-id $shareId --storage-type AzureFiles --share-name $share --account-name $AZURE_STORAGE_ACCOUNT --mount-path $mountPath --access-key $AZURE_STORAGE_KEY

az storage account keys list -g azure-func-dev-func-resource-group -n sharestorageacct --query '[0].value' -o tsv