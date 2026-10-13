# LibreWolf with my settings baked in. Replaces `librewolf` everywhere (via an overlay),
# so the plain `librewolf` in the main package list gets these changes.
# The settings themselves are in ~/.config/librewolf (prefs.js, policies.json), shared with the
# tablet, which uses the same two files. Policies: the "Dark space" theme (black with animated
# stars; enable it once in Add-ons → Themes) and the regular DuckDuckGo with suggestions (LibreWolf's
# built-in one is noai.duckduckgo.com, and without SuggestURLTemplate it offers no suggestions).
{ ... }:

{
  nixpkgs.overlays = [
    (final: prev: {
      librewolf = prev.librewolf.override {
        extraPrefs = builtins.readFile ../librewolf/prefs.js;
        extraPolicies = (builtins.fromJSON (builtins.readFile ../librewolf/policies.json)).policies;
      };
    })
  ];
}
