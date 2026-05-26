# Vibelytics Screen System

## Standard Screens
- Use the compact screen tokens in `VType` and `VSpace`.
- Use `StandardScreenAppBar` for push-screen chrome.
- Use `BottomActionBarSurface` for compact bottom CTA areas.
- Use `VIcons` for all non-brand icons.
- Prefer fixed token sizing over `Sizer` for typography and spacing.

Standard examples:
- upload and analysis flows
- settings and account screens
- profile management and detail flows
- gallery/detail/task screens

## Hero Screens
- Keep the larger title and spacing treatment for onboarding, marketing, celebratory, or blocking flows.
- Hero screens may use `AppTopBar` or `SliverAppTopBar`.
- Hero screens still normalize shared iconography through `VIcons`.

Hero examples:
- onboarding welcome/auth landing
- force update and offline interruptions
- other big-message surfaces whose primary job is emotional framing, not dense task work

## Classification Rule
- Default to `Standard`.
- Only choose `Hero` when the screen is clearly focused on a large message, brand moment, or interruption state.

## Responsive Rule
- Compact semantic tokens stay fixed in dp/sp.
- Use `Responsive.device` or layout-specific branching for tablet gutters and media layouts.
- Do not scale standard spacing and typography tokens through `Sizer`.
