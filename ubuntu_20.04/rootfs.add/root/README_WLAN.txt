Setting up WiFi:

  # iw dev wlan0 scan | grep ssid -i
    -- search output for desired SSID
  # wpa_passphrase <SSID> <password> >> /etc/wpa_supplicant/wpa_supplicant-wlan0.conf
  # systemctl restart wpa_supplicant@wlan0

