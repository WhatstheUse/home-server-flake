{ ... }:

{
  # Rootless Podman for user-level container workloads.
  #
  # Daemonless and rootless: containers started by a normal user run under that
  # user's subordinate UID/GID range (/etc/subuid, /etc/subgid), so a container
  # "root" maps to an unprivileged host UID with no access to other users' data
  # or host processes. No long-running root daemon (unlike Docker).
  #
  # Subuid/subgid ranges and the newuidmap/newgidmap setuid wrappers are already
  # provisioned for normal users, so enabling Podman is sufficient.
  virtualisation.podman = {
    enable = true;
    # dockerCompat intentionally left off — consumers invoke `podman` directly
    # (e.g. via an explicit binary path) rather than a `docker` shim.
  };
}
