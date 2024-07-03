#!/usr/bin/ bash

#bash options(optional)
set -euf  

OWNER_AUTH="kiran123"
LOCKOUT_AUTH="kiran123"
EK_NVindex=0x1c0000a
EK_NVsize=1000
EK_PUBKEY="ekpub.pem"


tpm2_clear() {

#TPM2_CLEAR=$(tpm2_clear ownerpasswd )

 if ! command -v tpm2_clear -c p&> /dev/null;
 then
  echo "Error: tpm2_getcap command not found. Please install tpm2-tools."
 exit 1
 fi
}



echo "======================================================="
echo "This is script to provision EK, AIK and SRK keys in the TPM"
echo "do run the script in superuser mode(root privileges)"
echo "======================================================="


echo -n "checking for tpm2 tools...................."

# Check if tpm2_toolsis available

 if ! command -v tpm2_getcap &> /dev/null;
 then
  echo "Error: tpm2_getcap command not found. Please install tpm2-tools."
  exit 1
 else
    echo  "OK "

 fi
 
 
##########################################################
#find TPM Manufacturer
############################################################

 echo -n "checking TPM manufacturer.................."
 # Get the manufacturer information using tpm2_getcap

 
 tpm_manufacturer=$(tpm2_getcap properties-fixed | grep -A 2 TPM2_PT_MANUFACTURER | grep -A 0 value: | awk '{print $2 $3}')
 
 
 if [ $? -eq 0 ]; then
    echo  "TPM manufacturer :  $tpm_manufacturer"
else
    echo  "Could not find TPM manufacturer "
fi


##########################################################
#clear exsing owner and lockout authorization
############################################################


echo  -n "reading current owner authorization......."

current_owner_auth=$(tpm2_getcap properties-variable | grep -A 0 ownerAuthSet: | awk '{print $2}')
 if [ $current_owner_auth -eq 1 ]; then
    echo  "Owner Authorization is already set.Need to clear"
    #tpm2_clear
 else
    echo  "Owner Authorization not Set "
fi
echo




##########################################################
#set owner and lockout authorization
############################################################

echo -n "setting owner and lockout authorization......"
current_owner_auth=$(tpm2_getcap properties-variable | grep -A 0 ownerAuthSet: | awk '{print $2}')
 if [ $current_owner_auth -eq 1 ]; then
    echo -n "Owner Authorization is already Set"
    #tpm2_clear
   
else
  tpm2_changeauth -c o $OWNER_AUTH
  tpm2_changeauth -c l $LOCKOUT_AUTH

fi
echo



##########################################################
#check for Endorsement certificate
############################################################
echo  "checking for EK in NV index..................$EK_NVindex"
echo  "......................................................."
tpm2_nvread -C o -s $EK_NVsize -o $EK_PUBKEY  -P $OWNER_AUTH $EK_NVindex
openssl x509 -inform der -in $EK_PUBKEY -noout -subject -issuer
echo  "......................................................."



##########################################################
#create primary
############################################################



sudo tpm2_createprimary -C o -P kiran123 -g sha256 -G ecc -c ECCprimary.ctx
 sudo tpm2_evictcontrol -C o -c ECCprimary.ctx -P kiran123
 sudo tpm2_create -C ECCprimary.ctx -G ecc -g sha256 -u Eccpub.pub  -r EccPriv.priv
 sudo tpm2_load -C ECCprimary.ctx -c ECCloadcontext.ctx -u Eccpub.pub  -r EccPriv.priv
 sudo tpm2_evictcontrol -C o -c ECCloadcontext.ctx -P kiran123 --output=persitenthandle.txt 0x81010003
 
 sudo tpm2_evictcontrol -C o -c ECCloadcontext.ctx -P kiran123 --output=persitenthandle.txt 0x81010003

------------------------------------------------------------------------------

#!/bin/bash
 
# Define variables
KEY_DIR="mok_keys"
MOK_CRT="${KEY_DIR}/MOK.crt"
MOK_REQUEST="${KEY_DIR}/MOK.der"
 
# Function to check the success of the last command
check_command() {
    if [ $? -ne 0 ]; then
        echo "Error: $1"
        exit 1
    fi
}
 
# Convert the MOK certificate to DER format
openssl x509 -in ${MOK_CRT} -outform DER -out ${MOK_REQUEST}
check_command "Failed to convert MOK certificate to DER format."
 
# Enroll the MOK key
sudo mokutil --import ${MOK_REQUEST}
check_command "Failed to import MOK certificate using mokutil."
 
# Notify the user about the next steps
echo "MOK enrollment request has been created. Please reboot the system and follow the instructions to complete the MOK enrollment process in the MOK Manager."
 
exit 0



!/bin/bash
 
# Define variables
KEY_DIR="mok_keys"
MOK_KEY="${KEY_DIR}/MOK.key"
MOK_DER="${KEY_DIR}/MOK.der"
MOK_CRT="${KEY_DIR}/MOK.crt"
KERNEL_IMAGE="/boot/vmlinuz-$(uname -r)"
BOOTLOADER_IMAGE="/boot/efi/EFI/ubuntu/grubx64.efi"
SIGNED_KERNEL="${KERNEL_IMAGE}.signed"
SIGNED_BOOTLOADER="${BOOTLOADER_IMAGE}.signed"
HASH_ALG="sha256"
 
# Function to check the success of the last command
check_command() {
    if [ $? -ne 0 ]; then
        echo "Error: $1"
        exit 1
    fi
}
 
# Create directory for keys
mkdir -p ${KEY_DIR}
check_command "Failed to create directory for MOK keys."
 
# Generate MOK private key and certificate
openssl req -new -x509 -newkey rsa:2048 -keyout ${MOK_KEY}  -outform DER -out ${MOK_DER} -nodes -days 36500 -subj "/CN=Smith and Nephew Custom Secure Boot Key/"
check_command "Failed to generate MOK key."
 
openssl x509 -in ${MOK_DER} -inform DER -out ${MOK_CRT}
check_command "Failed to generate MOK certificate."
 
# Sign the kernel
sudo sbsign --key ${MOK_KEY} --cert ${MOK_CRT} --output ${SIGNED_KERNEL} ${KERNEL_IMAGE}
check_command "Failed to sign the kernel image."
 
# Sign the bootloader
sudo sbsign --key ${MOK_KEY} --cert ${MOK_CRT} --output ${SIGNED_BOOTLOADER} ${BOOTLOADER_IMAGE}
check_command "Failed to sign the bootloader image."
 
# Verify the signed files
sbverify --cert ${MOK_CRT} ${SIGNED_KERNEL}
check_command "Failed to verify the signed kernel image."
 
sbverify --cert ${MOK_CRT} ${SIGNED_BOOTLOADER}
check_command "Failed to verify the signed bootloader image."
 
echo "Successfully generated MOK keys and signed kernel and bootloader images."
 
exit 0
