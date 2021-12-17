#!/usr/bin/env bash

[ -z "$CLIENT_KEY_FILE" ] && echo "Please specify CLIENT_KEY_FILE (this is the location of your client cert's private key" && exit 1
[ -z "$CLIENT_CERT_FILE" ] && echo "Please specify CLIENT_CERT_FILE (this is the location of your client cert file" && exit 1
[ -z "$USER_NAME" ] && echo "Please specify USER_NAME (this is the email address of the N26 user)" && exit 1
[ -z "$PASSWORD" ] && echo "Please specify PASSWORD (this is the password of the N26 user)" && exit 1
[ -z "$AES_SECRET_KEY" ] && echo "Please specify AES_SECRET_KEY (this is used to generate an example AES secret key/iv)" && exit 1
[ -z "$PISP_HOST" ] && echo "PISP_HOST not specified (this is the location of the PISP access host), defaulting to pisp.tech26.de" && export PISP_HOST=pisp.tech26.de
[ -z "$TEMP_FOLDER" ] && echo "Please specify TEMP_FOLDER (this is a folder which this script can create and destroy, and use to store temporary files)" && exit 1
[ -z "$PIN" ] && echo "Please specify PIN (this is the user's PIN, as a plain string)" && exit 1

# Log in and get an access token

token_json=$(curl -k --key $CLIENT_KEY_FILE --cert $CLIENT_CERT_FILE -s -X POST --data-urlencode 'grant_type=password' --data-urlencode "username=$USER_NAME" --data-urlencode "password=$PASSWORD" https://${PISP_HOST}/oauth2/token)

access_token=$(echo $token_json | jq .access_token | sed "s/^null$//" | tr -d '"')

if [ -z "$access_token" ]; then

# Assume MFA if token not immediately available.

mfa_token=$(echo $token_json | jq .mfaToken | sed "s/^null$//" | tr -d '"')

echo "MFA token: $mfa_token"

curl -k --key $CLIENT_KEY_FILE --cert $CLIENT_CERT_FILE -s -X POST -H 'Authorization:Basic YW5kcm9pZDpzZWNyZXQ=' -H "Content-Type: application/json" --data '{"mfaToken": "'$mfa_token'", "challengeType":"oob"}' https://$PISP_HOST/api/mfa/challenge
echo
echo "Please confirm on your paired phone.."

read -n 1 -p "Press enter when done:" mainmenuinput

access_token=$(curl -k --key $CLIENT_KEY_FILE --cert $CLIENT_CERT_FILE -s -X POST --data-urlencode 'grant_type=mfa_oob' --data-urlencode "mfaToken=$mfa_token" https://$PISP_HOST/oauth2/token | jq .access_token | tr -d '"' )

fi

echo "Access token: $access_token"

# Get a public key from the encryption key endpoint.

public_key=$(curl -k --key $CLIENT_KEY_FILE --cert $CLIENT_CERT_FILE -s -H "Authorization:Bearer $access_token" https://${PISP_HOST}/api/encryption/key | jq -r '.publicKey')

echo "Public key: $public_key"

# Generate an AES secret of your choice (here it is just based on the $AES_SECRET_KEY variable).

aes_secret_raw=$(openssl enc -nosalt -aes-256-cbc -pbkdf2 -k $AES_SECRET_KEY -P)
aes_key_hex=$(echo "$aes_secret_raw" | grep "key\s*=" | sed -e "s/.*=//")
aes_iv_hex=$(echo "$aes_secret_raw" | grep "iv\s*=" | sed -e "s/.*=//")

echo "AES key: $aes_key_hex, AES IV: $aes_iv_hex"

# Encode this encryption key as JSON; this is the secret that we will pass.

aes_key_base64=$(echo $aes_key_hex | xxd -r -p | base64)
aes_iv_base64=$(echo $aes_iv_hex | xxd -r -p | base64)
unencrypted_aes_secret=$(jq -n --arg key "$aes_key_base64" --arg iv "$aes_iv_base64" '{secretKey: $key, iv: $iv}')

echo "AES secret: $unencrypted_aes_secret"

# Encrypt the secret using the supplied public key.

rsa_public_key=$(echo -e "-----BEGIN PUBLIC KEY-----\n$public_key\n-----END PUBLIC KEY-----" | sed -r 's/(.{67})/\1\n/g')
mkdir -p $TEMP_FOLDER
echo "$rsa_public_key" > $TEMP_FOLDER/rsa_public_key.pem
encrypted_secret=$(echo $unencrypted_aes_secret | openssl rsautl -encrypt -inkey $TEMP_FOLDER/rsa_public_key.pem -pubin | base64 | tr -d '\n')
rm $TEMP_FOLDER/rsa_public_key.pem

echo "Encrypted AES secret: $encrypted_secret"

# Encrypt the PIN using your encryption key.

encrypted_pin=$(echo $PIN | tr -d '\n' | openssl enc -nosalt -aes-256-cbc -K $aes_key_hex -iv $aes_iv_hex | base64 | tr -d '\n')

echo "Encrypted PIN: $encrypted_pin"

# Post the headers as encrypted-secret and encrypted-pin to e.g. initiate a transaction.

curl -X POST -H "encrypted-secret: $encrypted_secret" -H "encrypted-pin: $encrypted_pin" -H "Authorization: Bearer ${access_token}" -H "Content-Type: application/json" --data '{"standingOrder":{"amount":"12.0","partnerIban":"ES2015632626323268851568","partnerName":"Pancho Villa","nextExecutingTS":"1583452800000","executionFrequency":"WEEKLY"}}' -k --key $CLIENT_KEY_FILE --cert $CLIENT_CERT_FILE https://${PISP_HOST}/api/transactions/so
