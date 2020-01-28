# Vault Kubernetes enable

```bash
kubectl port-forward -n consul sts/vault 8200

export VAULT_ADDR=http://localhost:8200
vault operator init
export VAULT_TOKEN=xxxx

vault audit enable file file_path=stdout
vault auth enable kubernetes

# Configure vault kubernetes integration
SA_TOKEN=$(kubectl get secret -n consul $(kubectl get serviceaccount -n consul vault -o jsonpath='{.secrets[0].name}') -ojsonpath='{.data.token}'| base64 -D)
SA_CA_CRT=$(kubectl get secret -n consul $(kubectl get serviceaccount -n consul vault -o jsonpath='{.secrets[0].name}') -ojsonpath='{.data.ca\.crt}'| base64 -D)
vault write auth/kubernetes/config \
  kubernetes_host=https://kubernetes.default.svc.cluster.local \
  kubernetes_ca_cert="$SA_CA_CRT" \
  token_reviewer_jwt="$SA_TOKEN"

# Create policy for prometheus
echo 'path "sys/metrics*" {capabilities = ["read", "list"]}' | vault policy write prometheus -

# Bind prometheus service account to prometheus policy
vault write auth/kubernetes/role/prometheus \
  bound_service_account_names=prometheus-prometheus \
  bound_service_account_namespaces=monitoring \
  policies=prometheus ttl=1h
```
