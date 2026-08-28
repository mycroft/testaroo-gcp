terraform {
  required_providers {
    googleworkspace = {
      source = "hashicorp/googleworkspace"
    }
  }
}

locals {
  # team-sre@... -> "Team Sre"
  group_names = {
    for email in var.emails :
    email => title(replace(split("@", email)[0], "-", " "))
  }
}

resource "googleworkspace_group" "group" {
  for_each    = toset(var.emails)
  email       = each.key
  name        = local.group_names[each.key]
  description = local.group_names[each.key]

  timeouts {
    create = "1m"
    update = "1m"
  }

  lifecycle {
    ignore_changes = [aliases] # gérés à la main
  }
}

resource "googleworkspace_group_settings" "settings" {
  for_each = toset(var.emails)
  email    = each.key

  allow_external_members  = var.allow_external_members
  who_can_join            = "INVITED_CAN_JOIN"
  who_can_post_message    = var.who_can_post_message
  who_can_view_group      = "ALL_MEMBERS_CAN_VIEW"
  who_can_view_membership = "ALL_MEMBERS_CAN_VIEW"
  who_can_discover_group  = "ALL_IN_DOMAIN_CAN_DISCOVER"

  timeouts {
    create = "1m"
    update = "1m"
  }

  depends_on = [googleworkspace_group.group]
}
