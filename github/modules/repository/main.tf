# Dépôt GitHub avec les conventions de tf-it/modules/github_private_repository :
# squash/rebase uniquement, suppression des branches fusionnées, branche par
# défaut explicite, et protection de la branche par défaut via un ruleset.

resource "github_repository" "this" {
  name        = var.name
  description = var.description
  visibility  = var.visibility
  topics      = var.topics

  allow_merge_commit     = false
  allow_squash_merge     = true
  allow_rebase_merge     = true
  allow_auto_merge       = var.allow_auto_merge
  delete_branch_on_merge = true
  auto_init              = true

  has_issues   = var.has_issues
  has_projects = false
  has_wiki     = false

  lifecycle {
    # auto_init crée le premier commit ; un changement ultérieur forcerait la recréation.
    ignore_changes = [auto_init]
  }
}

resource "github_repository_vulnerability_alerts" "this" {
  repository = github_repository.this.name
}

resource "github_branch" "default" {
  repository = github_repository.this.name
  branch     = var.default_branch
}

resource "github_branch_default" "this" {
  repository = github_repository.this.name
  branch     = github_branch.default.branch
}

# Protection de la branche par défaut. Ruleset plutôt que branch_protection :
# c'est la direction prise par tf-it (uses_ruleset) et l'API que GitHub fait évoluer.
resource "github_repository_ruleset" "default_branch" {
  name        = "${var.default_branch}-protection"
  repository  = github_repository.this.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  rules {
    deletion                = true
    non_fast_forward        = true # interdit les force-push
    required_linear_history = var.required_linear_history

    pull_request {
      required_approving_review_count   = var.required_approving_review_count
      dismiss_stale_reviews_on_push     = true
      require_code_owner_review         = false
      require_last_push_approval        = false
      required_review_thread_resolution = true
    }

    dynamic "required_status_checks" {
      for_each = length(var.status_check_contexts) > 0 ? [1] : []
      content {
        strict_required_status_checks_policy = true
        dynamic "required_check" {
          for_each = var.status_check_contexts
          content {
            context = required_check.value
          }
        }
      }
    }
  }

  # Les admins du dépôt peuvent contourner (équivalent enforce_admins = false).
  dynamic "bypass_actors" {
    for_each = var.admins_can_bypass ? [1] : []
    content {
      actor_id    = 5 # rôle RepositoryRole "admin"
      actor_type  = "RepositoryRole"
      bypass_mode = "always"
    }
  }

  depends_on = [github_branch_default.this]
}
