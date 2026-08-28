# Groupes gérés par Terraform. Un module par famille de groupes, comme tf-it.

locals {
  groups = {
    # groupe = membres (logins définis dans users.tf)
    cereales       = ["chocapic", "mielpops", "smacks"]
    serial-killers = ["emile-louis", "guy-georges", "michel-fourniret"]
  }

  memberships = merge([
    for group, members in local.groups : {
      for m in members : "${group}/${m}" => { group = group, user = m }
    }
  ]...)
}

module "groups" {
  source = "./modules/group"

  emails               = [for g in keys(local.groups) : "${g}@${var.domain}"]
  who_can_post_message = "ALL_IN_DOMAIN_CAN_POST"
}

resource "googleworkspace_group_member" "member" {
  for_each = local.memberships

  group_id = module.groups.groups["${each.value.group}@${var.domain}"].id
  email    = googleworkspace_user.user[each.value.user].primary_email
  role     = "MEMBER"
}
