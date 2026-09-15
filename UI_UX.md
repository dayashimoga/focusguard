# FocusGuard - UI/UX Design System & Ergonomics

## 1. Design Philosophy

The FocusGuard design language is engineered around **Ergonomic Mindfulness, Calm Authority, and Zero Visual Noise**. Digital wellbeing interfaces must promote focus and intentionality rather than stimulating dopamine loops.

---

## 2. Color Palette & Typography

### 2.1 Palette Tokens (Dark Theme / OLED Optimized)
- **Primary / Focus Active**: `#0D9488` (Teal 600 - calming, high clarity)
- **Primary Container / Glow**: `#14B8A6` (Teal 500)
- **Background / Canvas**: `#0D1117` (Deep Slate / Dark Charcoal)
- **Surface**: `#161B22` (Card and panel backgrounds)
- **Surface High**: `#21262D` (Elevated modals, chips, bottom sheets)
- **Break Active / Amber Warning**: `#F59E0B` (Amber 500)
- **Locked / Emergency Critical**: `#EF4444` (Rose / Crimson)
- **Text Primary**: `#F8FAFC` (Slate 50 - high contrast)
- **Text Secondary**: `#94A3B8` (Slate 400 - subdued guidance)
- **Border / Outline**: `#30363D` (Subtle boundary lines)

### 2.2 Typography
FocusGuard uses high-legibility geometric sans-serif fonts with distinct weight hierarchy:
- **Display Timer**: Monospace Tabular Figures (`fontFeatures: [FontFeature.tabularFigures()]`) to prevent jittering countdowns.
- **Headings**: Semibold (600) and Bold (700) with generous letter spacing.
- **Body**: Regular (400) and Medium (500) with 1.5 line-height for comfortable reading.

---

## 3. Responsive Layout Architecture

Implemented via [adaptive_scaffold.dart](file:///h:/focus/lib/presentation/widgets/adaptive_scaffold.dart):

```
+-------------------------------------------------------------------------+
| Screen Width < 600dp (Compact Phone)                                    |
| +---------------------------------------------------------------------+ |
| | Top App Bar (Title, Actions)                                        | |
| +---------------------------------------------------------------------+ |
| | Body Scrollable Content (Single Column)                             | |
| +---------------------------------------------------------------------+ |
| | Bottom Navigation Bar (5 Core Tabs)                                 | |
| +---------------------------------------------------------------------+ |
+-------------------------------------------------------------------------+

+-------------------------------------------------------------------------+
| Screen Width >= 600dp (Foldable / Tablet / Landscape)                   |
| +----------------+----------------------------------------------------+ |
| | Navigation Rail| Header Area                                        | |
| | (Left Pinned)  +---------------------------------+------------------+ |
| | - Home         | Master Panel                    | Detail Panel     | |
| | - Sessions     | (Lists, Profiles, Schedules)    | (Active HUD,     | |
| | - Limits       |                                 |  Config, Graphs) | |
| | - Insights     |                                 |                  | |
| | - Settings     |                                 |                  | |
| +----------------+---------------------------------+------------------+ |
+-------------------------------------------------------------------------+
```

---

## 4. Accessibility & Compliance (WCAG 2.1 AA)

- **Contrast Ratios**: All text-to-background contrast ratios exceed **7.1:1** for normal text and **4.5:1** for large display figures.
- **Touch Targets**: Minimum interactive touch target size is **48x48 dp** with minimum 8dp separation.
- **Screen Reader Support**: All custom painters (such as the circular countdown ring) implement semantic descriptions (`Semantics` widget) exposing current progress percentage and time remaining.
- **Haptic Feedback**: Meaningful, subtle haptics on timer start, break trigger, and restriction alerts.

---

## 5. Screen-by-Screen Specifications (13 Screens)

1. **`HomeScreen`**: Circular progress ring showing daily focus minutes, current active session widget, 1-tap quick start chips (15m, 25m, 45m, 60m), and upcoming schedules.
2. **`StartFocusScreen`**: Smooth duration slider (5m to 24h), profile selector carousel, restriction mode radio cards, allowed apps whitelist preview, and large confirmation button.
3. **`ActiveSessionScreen`**: Ambient dark HUD, high-visibility monotonic circular timer ring, break trigger button, pause friction button, and fail-safe Emergency Exit.
4. **`AppSelectionScreen`**: Search bar, category filters (Social, Gaming, Productivity, System), individual package checkboxes, select/deselect all, and system app protection warnings.
5. **`ProfilesScreen`**: Card list of reusable profiles (Work, Study, Deep Focus, Sleep, Custom), showing blocked app counts, restriction level badges, and edit/duplicate options.
6. **`SchedulesScreen`**: Calendar/weekly recurring overview, active day pills (Mon-Sun), start/end time pickers with spanning-midnight detection, and active/inactive toggles.
7. **`DailyLimitsScreen`**: Per-app allowance progress bars, notification threshold switches (80%, 90%), and auto-lock behavior toggles.
8. **`OverrideConfigScreen`**: Policy selection (Instant, Cooldown Delay, Mindful Phrase, Salted PIN), delay slider (1-15 min), phrase editor, and PIN setup dialog.
9. **`UsageInsightsScreen`**: Weekly focus time bar charts, completed vs abandoned session ratios, streak counters, and category distribution pie charts.
10. **`HistoryScreen`**: Chronological list of completed, cancelled, and emergency-exited sessions with duration, timestamps, and audit integrity badges.
11. **`SettingsScreen`**: Battery optimization status check, OEM background setup guide, theme selector, export/import JSON backup, and secure data wipe.
12. **`PermissionsScreen`**: Live capability matrix showing OS permission statuses with 1-tap grant buttons and diagnostic explanations.
13. **`HelpEmergencyScreen`**: Instant emergency dialer launcher, one-tap access to crisis and suicide prevention hotlines (988, 911, 112), and legal/safety disclaimers.
