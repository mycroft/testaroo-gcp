terramate {
  required_version = ">= 0.17"

  config {
    git {
      default_branch = "main"
      default_remote = "origin"
    }

    # Seuls les commits comptent : un working tree sale n'élargit jamais le
    # périmètre d'un run CI (même réglage que tf-it).
    change_detection {
      git {
        untracked   = "off"
        uncommitted = "off"
      }
    }
  }
}
