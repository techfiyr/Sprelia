# assets/

All app assets live here, grouped by purpose. See `doc/ASSET_LIBRARY.md` for rules,
the inventory and specs. This README and `ATTRIBUTION.md` are not bundled.

- `fonts/`: bundled fonts (with licence texts)
- `branding/logo/`, `branding/icons/`, `branding/marketing/`: brand sources (planned)
- `tutors/<tutor_id>/`: approved tutor avatars (planned). The `img_tutor_*.jpeg` files
  in `tutors/` are **unapproved candidates of unknown licence**. They are not bundled.
- `illustrations/`, `animations/`: planned

Code uses `AppAssets` (`lib/core/assets/app_assets.dart`), never string paths.
