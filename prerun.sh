#!/usr/bin/env bash
# Source this file before running `terraform apply`.

[ -f "id_rsa" ] || ssh-keygen

echo -n 'DO Token: '
read -sr TF_VAR_do_token
export TF_VAR_do_token
echo
ssh-add id_rsa
