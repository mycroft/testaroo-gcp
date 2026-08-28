# Utilisateurs du domaine. Un membre de groupe doit exister dans l'annuaire
# (ou être externe, ce qu'on n'autorise pas) : on les crée ici.

locals {
  users = {
    # login = { given, family }
    chocapic         = { given = "Chocapic", family = "Nestlé" }
    mielpops         = { given = "Miel", family = "Pops" }
    smacks           = { given = "Smacks", family = "Kellogg's" }
    emile-louis      = { given = "Émile", family = "Louis" }
    guy-georges      = { given = "Guy", family = "Georges" }
    michel-fourniret = { given = "Michel", family = "Fourniret" }
  }
}

resource "random_password" "initial" {
  for_each = local.users
  length   = 24
}

resource "googleworkspace_user" "user" {
  for_each = local.users

  primary_email = "${each.key}@${var.domain}"
  name {
    given_name  = each.value.given
    family_name = each.value.family
  }

  # Mot de passe initial jetable ; à changer à la première connexion.
  password                      = random_password.initial[each.key].result
  change_password_at_next_login = true

  lifecycle {
    ignore_changes = [password] # ne pas écraser le mot de passe choisi par l'utilisateur
  }
}
