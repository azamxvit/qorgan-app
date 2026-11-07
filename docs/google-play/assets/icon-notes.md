# Google Play icon

The owner requested a black background for the existing Qorğan logo on 7 November 2026.

Final listing asset: `store-icon-black.png`, exported at 512×512 from `store-icon-black.svg` with `rsvg-convert`. The SVG differs from `store-icon.svg` only in the background fill (`#FFFFFF` → `#000000`); all original logo paths, transforms, padding and mint fill `#3AD99A` are preserved. The original white assets remain available. This changes the Play listing icon only, not the installed Android launcher icon or UI.

A built-in imagegen preview was also generated using the white icon as its edit target and the instruction to change only the background to solid black, including the negative spaces, while preserving the logo. It was **not used as the final listing asset**: the editable project SVG gives exact geometry and colour. No image-generation API/CLI fallback was used.

Export command:

```sh
rsvg-convert docs/google-play/assets/store-icon-black.svg -o docs/google-play/assets/store-icon-black.png
```
