locals {
  common_tags = {
#    environment      = "${data.external.configuration.result.environment}"
    environment      = "development"
  }
}

data "template_file" "public_cidrsubnet" {
  count = "${data.external.configuration.result.vpc_subnet_count}"

  template = "$${cidrsubnet(vpc_cidr,8,current_count)}"

  vars {
    vpc_cidr      = "${data.external.configuration.result.vpc_cidr_range}"
    current_count = "${count.index*2+1}"
  }
}

data "template_file" "private_cidrsubnet" {
  count = "${data.external.configuration.result.vpc_subnet_count}"

  template = "$${cidrsubnet(vpc_cidr,8,current_count)}"

  vars {
    vpc_cidr      = "${data.external.configuration.result.vpc_cidr_range}"
    current_count = "${count.index*2}"
  }
}

# TODO Get configs from repository
data "external" "configuration" {
  program = ["bash", "../scripts/myscript.sh"]

  # Optional request headers
  #query = {  }
}
