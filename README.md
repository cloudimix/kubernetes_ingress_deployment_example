# kubernetes_ingress_deployment_example
Automatic Deployment of an Example App with Ingress Rules on Oracle Cloud (Always Free) using Ansible and Terraform

- make && make clean && make install && make app

- sudo chmod 775 dynamic_inventory.py (if necessary)

- IC_IP=$(python3 -c 'import subprocess; node_public_ip = subprocess.run(["terraform", "output", "-raw", "LB_public_ip"], stdout=subprocess.PIPE).stdout.decode("utf-8"); print(node_public_ip)')
- IC_HTTPS_PORT=443

- curl --resolve cafe.example.com:$IC_HTTPS_PORT:$IC_IP https://cafe.example.com:$IC_HTTPS_PORT/coffee --insecure
- curl --resolve cafe.example.com:$IC_HTTPS_PORT:$IC_IP https://cafe.example.com:$IC_HTTPS_PORT/tea --insecure
