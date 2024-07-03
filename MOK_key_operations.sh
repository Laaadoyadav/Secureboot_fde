#==================== Assigning Variable =================================
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

#==================== Checking Dependencies=================================
#!/bin/bash
echo Checking if all the dependencies are installed or not



if ! command -v jq &> /dev/null; then
    echo "Expect is not installed. Installing..."

    # Install expect on Ubuntu
    
    sudo apt-get install expect

    # Verify installation
    if ! command -v jq &> /dev/null; then
        echo "Expect installation failed. Please install jq manually."
        exit 1
    else
        echo "Expect has been successfully installed."
    fi
else
    echo "Expect is already installed."
fi

if ! command -v jq &> /dev/null; then
    echo "jq is not installed. Installing..."

    # Install jq on Ubuntu
    
    sudo apt-get install -y jq

    # Verify installation
    if ! command -v jq &> /dev/null; then
        echo "jq installation failed. Please install jq manually."
        exit 1
    else
        echo "jq has been successfully installed."
    fi
else
    echo "jq is already installed."
fi

#====================    End of Checking Dependencies  ==========================



#==================== Creating MOK keys  ==========================

#==================== MOK Keys Created  ==========================
# Function to check the success of the last command
check_command() {
    if [ $? -ne 0 ]; then
        echo "Error: $1"
        exit 1
    fi
}
 #==============================Create directory for keys=========================

mkdir -p ${KEY_DIR}
check_command "Failed to create directory for MOK keys."
 #=======================-------------------------=========================
 
 
#==================Generate MOK private key and certificate=========================
# 
openssl req -new -x509 -newkey rsa:2048 -keyout ${MOK_KEY}  -outform DER -out ${MOK_DER} -nodes -days 36500 -subj "/CN=Smith and Nephew Custom Secure Boot Key/"
check_command "Failed to generate MOK key."

openssl x509 -in ${MOK_DER} -inform DER -out ${MOK_CRT}
check_command "Failed to generate MOK certificate."

#=======================-------------------------========================= 


#==============================Sign the kernel=========================

sudo sbsign --key ${MOK_KEY} --cert ${MOK_CRT} --output ${SIGNED_KERNEL} ${KERNEL_IMAGE}
check_command "Failed to sign the kernel image."
#=======================-------------------------=========================
 
#==============================Sign the bootloader=========================

sudo sbsign --key ${MOK_KEY} --cert ${MOK_CRT} --output ${SIGNED_BOOTLOADER} ${BOOTLOADER_IMAGE}
check_command "Failed to sign the bootloader image."
#=======================-------------------------=========================
 
 
#==============================Verify the signed files=========================

sbverify --cert ${MOK_CRT} ${SIGNED_KERNEL}
check_command "Failed to verify the signed kernel image."

sbverify --cert ${MOK_CRT} ${SIGNED_BOOTLOADER}
check_command "Failed to verify the signed bootloader image."
#=======================-------------------------========================= 

echo "Successfully generated MOK keys and signed kernel and bootloader images." 


#=======================  Mok reset  ========================= 



# Bash commands
password=$(jq -r '.Mok_password' password.json)



# Using Expect within Bash using a here document
expect <<EOF
spawn mokutil --import ${MOK_DER}

# Expect and send password entry
expect "input password: "
send -- "$password\r"

expect "input password again: "
send -- "$password\r"

EOF
#=======================-------------------------========================= 


 
exit 0



