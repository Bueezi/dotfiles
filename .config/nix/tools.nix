{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    fzf bat tealdeer delta lazygit yt-dlp exiftool
    nmap whois socat iperf3
    radare2 ltrace binwalk sleuthkit testdisk ffuf sqlmap john hashcat
    (python3.withPackages (ps: [ ps.pwntools ]))   # the only python3: a second one collides
  ];

  programs.zoxide.enable = true;
  # Wrappers with capture rights, so neither needs sudo
  programs.mtr.enable = true;
  programs.tcpdump.enable = true;
  users.users.ben.extraGroups = [ "pcap" ];
}
