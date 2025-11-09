# AWS Network Firewall

Protecting inbound and outbound traffic in a VPC using AWS Network Firewall.

https://aws.amazon.com/blogs/networking-and-content-delivery/deployment-models-for-aws-network-firewall/

<img src=".assets/firewall.png" />

Copy the template file:

```sh
cp config/template.auto.tfvars .auto.tfvars
```

Create the resources:

```sh
terraform init
terraform apply
```

To test inbound drop, set your IP address in the `.auto.tfvars` file:

```terraform
ip_to_drop = "1.2.3.4"
```
