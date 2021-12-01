data "local_file" "traffic_policy_template" {
  filename = "./traffic-policy.json.tmpl"
}

data "template_file" "traffic_policy_input" {
  template = data.local_file.traffic_policy_template.content
  vars = {
    domain1 = module.epoch_store_front_frankfurt.API_DOMAIN_NAME
    domain2 = module.epoch_store_front_paris.API_DOMAIN_NAME
    healthcheck1 = module.epoch_store_front_frankfurt.healthcheckid
    healthcheck2 = module.epoch_store_front_paris.healthcheckid
  }
}

resource "local_file" "traffic_policy" {
    content     = data.template_file.traffic_policy_input.rendered
    filename = "./traffic-policy.json"
}

resource "null_resource" "create_traffic_policy" {

  provisioner "local-exec" {
    command = "aws route53 create-traffic-policy --name epochstore --document file://traffic-policy.json"
  }

  depends_on = [
    module.epoch_store_front_paris,
    module.epoch_store_front_frankfurt
  ]
}

resource "time_sleep" "policy_record_creation" {
  create_duration = "10s"

  depends_on = [
    null_resource.create_traffic_policy
  ]
}

resource "null_resource" "create_policy_record" {

  provisioner "local-exec" {
    command = "aws route53 create-traffic-policy-instance --hosted-zone-id ${module.epoch_store_front_frankfurt.zone_id} --name api.epoch-store.xyz --ttl 60  --traffic-policy-id $(aws route53 list-traffic-policies --query 'TrafficPolicySummaries[0].Id' | sed 's/\"//g') --traffic-policy-version 1"
  }

  depends_on = [
      time_sleep.policy_record_creation
  ]
}

resource "null_resource" "delete_traffic_policy" {

  provisioner "local-exec" {
    when    = destroy
    command = "aws route53 delete-traffic-policy --id $(aws route53 list-traffic-policies --query 'TrafficPolicySummaries[0].Id' | sed 's/\"//g') --traffic-policy-version 1"
  }

#   depends_on = [
#       time_sleep.policy_record_deletion,
#       null_resource.delete_policy_record
#   ]
}

resource "time_sleep" "policy_record_deletion" {
  destroy_duration = "40s"

  depends_on = [
    null_resource.delete_traffic_policy
  ]
}

resource "null_resource" "delete_policy_record" {

  provisioner "local-exec" {
    when    = destroy
    command = "aws route53 delete-traffic-policy-instance --id $(aws route53 list-traffic-policy-instances --query 'TrafficPolicyInstances[0].Id'| sed 's/\"//g')"
  }

  depends_on = [
      time_sleep.policy_record_deletion
  ]
}