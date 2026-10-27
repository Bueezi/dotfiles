# Laptop only (Ryzen 7430U, isLaptop = true): power, the Wi-Fi card, lid and hibernate
{ lib, pkgs, isLaptop, ... }:

{
  config = lib.mkIf isLaptop {
    # Switch profile automatically on AC/battery
    services.udev.extraRules = ''
      SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="0", RUN+="${pkgs.power-profiles-daemon}/bin/powerprofilesctl set power-saver"
      SUBSYSTEM=="power_supply", ATTR{type}=="Mains", ATTR{online}=="1", RUN+="${pkgs.power-profiles-daemon}/bin/powerprofilesctl set balanced"
    '';

    # Realtek (rtw89) Wi-Fi card fix
    networking.networkmanager.wifi.powersave = false;
    boot.extraModprobeConfig = ''
      options rtw89_core disable_ps_mode=y
      options rtw89_pci disable_aspm_l1=y disable_aspm_l1ss=y disable_clkreq=y
    '';

    hardware.bluetooth.powerOnBoot = false;   # radio off until you need it (bluetooth.sh)

    services.logind.settings.Login.HandleLidSwitch = "suspend-then-hibernate";
    # How long to sleep before switching to hibernate
    systemd.sleep.settings.Sleep.HibernateDelaySec = "30min";
    boot.resumeDevice = "/dev/disk/by-uuid/8ac0d876-3d7b-485a-8948-4ccd737b8d5f";
  };
}
