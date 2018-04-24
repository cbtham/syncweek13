#!/bin/bash
echo "Sourcing vars from conf.env"
source conf2.env

echo "Obtaining connection string..."
export SA_CONN=`az storage account show-connection-string -g $RG -n $STO_ACC_NAME -o tsv`

echo "Creating file share ${STO_FILE_SHARE_SAMPLE}"
az storage share create --account-name $STO_ACC_NAME --name $STO_FILE_SHARE_SAMPLE --connection-string $SA_CONN

echo "Creating directory ${STO_DIR_SAMPLE}"
az storage directory create --share-name $STO_FILE_SHARE  --name $STO_DIR_SAMPLE --connection-string $SA_CONN



#Using blob porter
echo "uploading the files"
blobporter -f "https://raw.githubusercontent.com/Microsoft/CNTK/v2.3/Examples/Image/Classification/ResNet/Python/resnet_models.py" \
 -c $STO_DIR_SAMPLE -n resnet_models.py -t http-blockblob
