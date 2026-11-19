{ lib, pkgs, isLaptop, ... }:

{
  config = lib.mkIf isLaptop {
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

    hardware.bluetooth.powerOnBoot = true;

    services.logind.settings.Login.HandleLidSwitch = "suspend-then-hibernate";
    systemd.sleep.settings.Sleep.HibernateDelaySec = "30min";
    # No boot.resumeDevice: systemd saves where it hibernated in an EFI variable and resumes from there
    swapDevices = [ { device = "/var/lib/swapfile"; size = 16 * 1024; } ];   # MiB, >= RAM; inside LUKS
  };
}
