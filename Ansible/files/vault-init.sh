#!/bin/sh

echo "Initializing Vault..."

#Init
vault operator init -key-shares=5 -key-threshold=3 -format=json > /tmp/cluster-keys.json
VAULT_ROOT_TOKEN=$(jq -r '.root_token' /tmp/cluster-keys.json)
vault operator unseal $(jq -r '.unseal_keys_b64[0]' /tmp/cluster-keys.json)
vault operator unseal $(jq -r '.unseal_keys_b64[1]' /tmp/cluster-keys.json)
vault operator unseal $(jq -r '.unseal_keys_b64[2]' /tmp/cluster-keys.json)

vault login $VAULT_ROOT_TOKEN

#Setup Root CA
echo "Configuring Root CA..."
vault secrets enable pki
vault secrets tune -max-lease-ttl=87600h pki
vault write -field=certificate pki/root/generate/internal common_name="Lab Root CA" ttl=87600h > /tmp/Lab_Root_CA.crt

#Setup Intermediate CA
echo "Configuring Intermediate CA..."
vault secrets enable -path=pki_int pki
vault secrets tune -max-lease-ttl=43800h pki_int
vault write -field=csr pki_int/intermediate/generate/internal common_name="Lab Intermediate CA" > /tmp/pki_intermediate.csr

#Sign Intermediate with Root
vault write -field=certificate pki/root/sign-intermediate csr=@/tmp/pki_intermediate.csr format=pem_bundle ttl="43800h" > /tmp/intermediate.cert.pem
vault write pki_int/intermediate/set-signed certificate=@/tmp/intermediate.cert.pem

#Configure PKI Roles and URLs
vault write pki_int/roles/lab-internal-role allowed_domains="lab.internal,svc.cluster.local" allow_subdomains=true max_ttl="720h"
vault write pki_int/config/urls issuing_certificates="http://vault.vault.svc:8200/v1/pki_int/ca" crl_distribution_points="http://vault.vault.svc:8200/v1/pki_int/crl"

#Enable Kubernetes Auth
echo "Enabling Kubernetes Auth..."
vault auth enable kubernetes
vault write auth/kubernetes/config kubernetes_host="https://kubernetes.default.svc:443"

#Configure Cert-Manager Access
echo "Configuring Cert-Manager Policies..."
cat <<EOF > /tmp/cert-manager-policy.hcl
path "pki_int/sign/lab-internal-role" { capabilities = ["update"] }
EOF
vault policy write cert-manager-policy /tmp/cert-manager-policy.hcl
vault write auth/kubernetes/role/cert-manager-role bound_service_account_names=cert-manager bound_service_account_namespaces=cert-manager policies=cert-manager-policy ttl=24h

#Configure External Secrets Operator Access
echo "Configuring ESO Policies..."
vault secrets enable -path=secret kv-v2
cat <<EOF > /tmp/eso-policy.hcl
path "secret/data/*" { capabilities = ["read"] }
EOF
vault policy write eso-policy /tmp/eso-policy.hcl
vault write auth/kubernetes/role/eso-role bound_service_account_names=external-secrets bound_service_account_namespaces=external-secrets policies=eso-policy ttl=24h

echo "Vault Initialization and Setup Complete."