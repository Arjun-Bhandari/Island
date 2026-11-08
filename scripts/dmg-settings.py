# dmgbuild settings for the drag-to-install window. Icon positions must match
# the arrow/halos drawn by scripts/dmg-background.swift.
app = defines["app"]  # noqa: F821 (injected by dmgbuild)

format = "UDZO"
filesystem = "HFS+"
files = [app]
symlinks = {"Applications": "/Applications"}
icon = "Resources/AppIcon.icns"
badge_icon = None

background = "Resources/dmg/background.tiff"
# Height includes the ~32pt title bar, so all 400pt of artwork stays visible.
window_rect = ((200, 140), (660, 432))
default_view = "icon-view"
show_status_bar = False
show_tab_view = False
show_toolbar = False
show_pathbar = False
show_sidebar = False
show_icon_preview = False

icon_size = 112
text_size = 13
icon_locations = {
    "Island.app": (165, 200),
    "Applications": (495, 200),
}
hide_extensions = ["Island.app"]
