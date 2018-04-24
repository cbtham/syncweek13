#!/bin/bash
source conf.env
# Registering providers
az provider register -n Microsoft.Batch
az provider register -n Microsoft.BatchAI


# Obtain Service principal
echo "Make sure you are logged in to your subscription with 'az login'"
export DEFAULT_ACCOUNT=`az account show -o tsv`
DEFAULT_ACCOUNT_ID=$(printf %s "$DEFAULT_ACCOUNT" | cut -f2)
if [ -z "$DEFAULT_ACCOUNT_ID" ]; then
    echo "Your subscription couldn't be found, make sure you have logged in."
    exit 1
else
    echo "You are connected to: "
    echo $DEFAULT_ACCOUNT
    echo "Running interactive script to get a Service Principal"
    bash getAzureServicePrincipal.sh
    echo "Sourcing Service Principal"
    source sp.env
    echo "Give Batch AI AD Network Contributor"
    az role assignment create --scope /subscriptions/$AZURE_SUBSCRIPTION_ID --role "Network Contributor" --assignee $AZURE_CLIENT_ID
    echo "Creating resource group named ${RG} in ${LOC}"
    az group create --name $RG --location $LOC

    echo "Creating Storage Account named: ${STO_ACC_NAME}"
    az storage account create --name $STO_ACC_NAME -g $RG --sku Standard_LRS
    echo "Obtaining connection string..."
    export SA_CONN=`az storage account show-connection-string -g $RG -n $STO_ACC_NAME -o tsv`
    echo "export SA_CONN=${SA_CONN}" >> conf.env
    echo "Creating file share ${STO_FILE_SHARE}"
    az storage share create --account-name $STO_ACC_NAME --name $STO_FILE_SHARE --connection-string $SA_CONN
    echo "Creating directory ${STO_DIR}"
    az storage directory create --share-name $STO_FILE_SHARE  --name $STO_DIR --connection-string $SA_CONN


    echo "Create Batch AI cluster '$CLUSTER_NAME'"
    az batchai cluster create --name $CLUSTER_NAME --vm-size $CLUSTER_SKU  \
    --image UbuntuLTS --min 1 --max 1 --storage-account-name $STO_ACC_NAME \
    --afs-name $STO_FILE_SHARE --afs-mount-path $STO_DIR \
    --user-name $CLUSTER_USERNAME --password $CLUSTER_PASSWORD \
    --resource-group $RG --location $LOC

    az batchai cluster show -n $CLUSTER_NAME -g $RG -o table 

fi


