loadTemplate("org.kde.plasma.desktop.defaultPanel")

var desktopsArray = desktopsForActivity(currentActivity());

for (var j = 0; j < desktopsArray.length; j++) {
    var desktop = desktopsArray[j];

    desktop.wallpaperPlugin = "org.kde.image";
    desktop.currentConfigGroup = Array(
        "Wallpaper",
        "org.kde.image",
        "General"
    );

    desktop.writeConfig(
        "Image",
        "file:///usr/share/wallpapers/Octlitch/3d-model.jpg"
    );
}
