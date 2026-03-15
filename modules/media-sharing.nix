{ username, ... }:

{
  # Create a shared media group for Syncthing and Jellyfin access
  users.groups.media = {
    members = [ username "jellyfin" "audiobookshelf" ];
  };

  # Ensure proper permissions on media directories
  systemd.tmpfiles.rules = [
    # Jellyfin media folders - user:media with group write
    "d /storage/media/videos 2775 ${username} media -"
    "d /storage/media/music 2775 ${username} media -"

    # Audiobookshelf folders - user:media with group write
    "d /storage/audiobooks/library 2775 ${username} media -"

    # Podcasts - separate dataset
    "d /storage/podcasts 2775 ${username} media -"

    # eBooks - user:media with group write
    "d /storage/ebooks 2775 ${username} media -"

    # Syncthing folders
    "d /storage/syncthing/sync 0755 ${username} users -"
    "d /var/lib/syncthing 0755 ${username} users -"
  ];
}
