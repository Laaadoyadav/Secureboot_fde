#!/bin/bash

# Function to generate a random password
generate_password() {
    < /dev/urandom tr -dc 'A-Za-z0-9!"#$%&'\''()*+,-./:;<=>?@[\]^_`{|}~' | head -c 16
}

# Number of passwords to generate
num_passwords=4


# Names to prefix passwords
names=("Serial Number" "Mok_password" "Master_password" "TPM_owner_Password" "BIOS_password")

# Array to store passwords
passwords=()
echo "Enter the serial number of the Console :"
read Serial_number
passwords[0]=$Serial_number

# Generate passwords
for ((i = 1; i <= num_passwords; i++)); do
    passwords[$i]=$(generate_password)
done

# Create a JSON object
json_string="{"
for ((i = 0; i <= num_passwords; i++)); do
    if [ $i -gt 0 ]; then
        json_string+=", "
    fi
    json_string+="\"${names[$i]}\": \"${passwords[$i]}\""
done
json_string+="}}"

# Output JSON to file
output_file="passwords.json"
echo $json_string > $output_file

echo "Passwords saved to $output_file"
