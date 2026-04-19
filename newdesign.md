# GojoCalories — Full UI/UX Design Prompt

> A full-featured calorie & nutrition tracking mobile app (iOS + Android).
> Clone of Cal AI. Rebrand: **GojoCalories**. Same features, same layout logic, new identity.
> Stack: **Flutter**. Frontend-only spec.

---

## 1. Brand Identity

| Token | Value |
|---|---|
| App Name | GojoCalories |
| Logo Icon | Avocado — custom SVG (`assets/icons/avocado.svg`) via `flutter_svg` |
| Tagline | *Track smarter. Eat better.* |
| Streak Icon | Flame SVG (orange gradient `#FF7A00 → #FFA726`) |
| Primary Accent | Teal `#00B4CC` |
| Primary Dark | Deep Teal `#007D8F` |
| Primary Light | Soft Teal `#E0F8FB` |
| CTA / FAB | Deep Teal `#007D8F` |
| Danger / Selected Date | Red `#E53935` |
| Streak / Fire | Orange `#FF7A00` |

---

## 2. Color System (Flutter `AppColors`)

Define in `lib/core/theme/app_colors.dart`:

```dart
class AppColors {
  // ── Backgrounds & Surfaces ────────────────────────────────
  static const Color background       = Color(0xFFF2F2F7); // screen bg (iOS system gray)
  static const Color surface          = Color(0xFFFFFFFF); // card bg
  static const Color surfaceMuted     = Color(0xFFF5F5F5); // inner tiles, exercise rows
  static const Color surfaceTealLight = Color(0xFFE0F8FB); // teal-tinted bg (chip active)

  // ── Text ──────────────────────────────────────────────────
  static const Color textPrimary      = Color(0xFF0A0A0A);
  static const Color textSecondary    = Color(0xFF6B6B6B);
  static const Color textPlaceholder  = Color(0xFFADADAD);

  // ── Borders & Dividers ────────────────────────────────────
  static const Color border           = Color(0xFFE8E8E8);
  static const Color ringTrack        = Color(0xFFEBEBEB);
  static const Color inactive         = Color(0xFF9E9E9E);

  // ── Primary Teal Palette ──────────────────────────────────
  static const Color primary          = Color(0xFF00B4CC); // main teal — rings, underlines, dots
  static const Color primaryDark      = Color(0xFF007D8F); // CTA buttons, FAB, chart line
  static const Color primaryLight     = Color(0xFFE0F8FB); // selected chip bg, tag bg
  static const Color primaryMid       = Color(0xFF00A0B4); // calorie ring arc fill

  // ── Macro Semantic Colors ─────────────────────────────────
  static const Color fire             = Color(0xFFFF7A00); // streak, flame icon
  static const Color fireLight        = Color(0xFFFFA726); // streak dot filled
  static const Color protein          = Color(0xFFFF6B6B); // salmon-red
  static const Color carbs            = Color(0xFFD4A017); // wheat-gold
  // NOTE: fats changed from blue → violet to avoid clash with teal primary
  static const Color fats             = Color(0xFF8B6FD4); // soft violet

  // ── States ────────────────────────────────────────────────
  static const Color danger           = Color(0xFFE53935); // selected date, errors
  static const Color streakInactive   = Color(0xFFD9D9D9);
}
```

> **Fats color rationale:** Original `#5B9BD5` (blue) is too close to the teal primary. `#8B6FD4` (soft violet) keeps protein/carbs/fats all visually distinct on the same screen.

---

## 3. Typography

**Flutter font:** `GoogleFonts.inter()` via `google_fonts` package.
Define in `lib/core/theme/app_text_styles.dart`:

```dart
class AppTextStyles {
  // Hero number — calorie count "2284"
  static const heroNumber = TextStyle(
    fontSize: 48, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary, height: 1.0,
  );

  // Screen title — "Progress"
  static const screenTitle = TextStyle(
    fontSize: 32, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.2,
  );

  // Section header — "Recently uploaded"
  static const sectionHeader = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.3,
  );

  // Card heading — "My Weight"
  static const cardHeading = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.4,
  );

  // Card value — "55 kg"
  static const cardValue = TextStyle(
    fontSize: 28, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.1,
  );

  // Macro value — "159g"
  static const macroValue = TextStyle(
    fontSize: 20, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, height: 1.2,
  );

  // Macro label — "Protein left"
  static const macroLabel = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.4,
  );

  // Nav label
  static const navLabelActive = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.0,
  );
  static const navLabelInactive = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w400, color: AppColors.inactive, height: 1.0,
  );

  // Body bold — food/suggestion names
  static const bodyBold = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, height: 1.4,
  );

  // Body regular — subtitles, descriptions
  static const bodyRegular = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary, height: 1.4,
  );

  // Button label
  static const buttonLabel = TextStyle(
    fontSize: 16, fontWeight: FontWeight.w600,
    color: Colors.white, height: 1.0,
  );
}
```

---

## 4. Spacing & Grid

Define in `lib/core/theme/app_spacing.dart`:

```dart
class AppSpacing {
  static const double xs    =  4.0;
  static const double sm    =  8.0;
  static const double md    = 16.0;
  static const double lg    = 24.0;
  static const double xl    = 32.0;
  static const double xxl   = 48.0;

  static const double screenPadding = 16.0; // horizontal page insets
  static const double cardPadding   = 16.0; // inner card padding all sides
  static const double cardGap       = 12.0; // vertical gap between cards
  static const double macroTileGap  = 10.0; // gap between 3 macro tiles
  static const double navHeight     = 72.0; // + MediaQuery.of(ctx).padding.bottom
  static const double fabSize       = 60.0;
  static const double fabMargin     = 20.0;
}
```

---

## 5. Border Radius

```dart
class AppRadius {
  static const double card    = 20.0; // main white cards
  static const double tile    = 16.0; // macro tiles, exercise rows
  static const double chip    = 999.0; // duration pills, pill buttons
  static const double input   = 14.0; // text input fields
  static const double button  = 999.0; // Manual / Voice Log outline buttons
  static const double cta     = 18.0; // full-width Continue / primary CTA
  static const double fab     = 30.0; // circular FAB
  static const double avatar  = 999.0; // user avatar circle
  static const double thumb   = 12.0; // food image thumbnails
}
```

---

## 6. Shadows & Elevation

```dart
class AppShadows {
  static const cardShadow = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 2)),
  ];

  static const cardElevated = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 20, offset: Offset(0, 4)),
  ];

  static const fabShadow = [
    BoxShadow(color: Color(0x40000000), blurRadius: 16, offset: Offset(0, 4)),
  ];

  static const navShadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 0, offset: Offset(0, -1)),
  ];

  // Modal scrim: ModalBarrier(color: Color(0x59000000)) — ~35% black
}
```

---

## 7. Iconography

**Flutter packages:**
- `lucide_icons_flutter` — primary icon set (outline, consistent 1.8px stroke)
- `flutter_svg` — avocado logo + flame gradient SVG

**Size constants:**
```dart
class AppIconSize {
  static const double nav    = 24.0; // bottom nav items
  static const double card   = 28.0; // inside macro ring center
  static const double action = 36.0; // FAB grid cells
  static const double list   = 22.0; // exercise option rows
  static const double small  = 18.0; // inline (flame next to calories)
}
```

### Icon Map

| Location | Flutter Icon | Color |
|---|---|---|
| App logo | `SvgPicture.asset('assets/icons/avocado.svg')` | `AppColors.primary` |
| Streak badge | `SvgPicture.asset('assets/icons/flame_gradient.svg')` | (gradient, no tint) |
| Home nav | `LucideIcons.house` | active: `textPrimary` / inactive: `inactive` |
| Progress nav | `LucideIcons.barChart2` | active: `textPrimary` / inactive: `inactive` |
| Groups nav | `LucideIcons.users` | `inactive` |
| Profile nav active | Filled circle `Container` | `AppColors.primary` |
| FAB | `LucideIcons.plus` | `Colors.white` |
| Protein macro | `LucideIcons.beef` (or custom SVG) | `AppColors.protein` |
| Carbs macro | `LucideIcons.wheat` | `AppColors.carbs` |
| Fats macro | `LucideIcons.droplets` | `AppColors.fats` |
| Log Exercise | `LucideIcons.footprints` | `textPrimary` |
| Saved Foods | `LucideIcons.bookmark` | `textPrimary` |
| Food Database | `LucideIcons.search` | `textPrimary` |
| Scan Food | `LucideIcons.scanLine` | `textPrimary` |
| Run | `LucideIcons.footprints` | `textPrimary` |
| Weight Lifting | `LucideIcons.dumbbell` | `textPrimary` |
| Describe workout | `LucideIcons.pencil` | `textPrimary` |
| Manual calories | `LucideIcons.flame` | `textPrimary` |
| Barcode | `LucideIcons.barcode` | `textPrimary` |
| Food label | `LucideIcons.tag` | `textPrimary` |
| Gallery | `LucideIcons.image` | `textPrimary` |
| Voice Log | `LucideIcons.mic` | `textPrimary` |
| Nutrition Goal | `LucideIcons.circleDashed` | `textPrimary` |
| Language | `LucideIcons.languages` | `textPrimary` |
| Preferences | `LucideIcons.settings2` | `textPrimary` |
| Personal Details | `LucideIcons.badgeCheck` | `textPrimary` |
| Invite/Refer | `LucideIcons.userPlus` | `textPrimary` |
| Calories inline | `LucideIcons.flame` | `AppColors.fire` |
| Back arrow | `LucideIcons.arrowLeft` | `textPrimary` |
| Chevron right | `LucideIcons.chevronRight` | `inactive` |
| Edit | `LucideIcons.pencil` | `inactive` |

---

## 8. Component Library

### 8.1 Bottom Navigation Bar

```
Widget type: custom Stack over body content (not Material BottomNavigationBar)
Height: 72.0 + MediaQuery.of(context).padding.bottom
Background: AppColors.surface
Top edge: BoxShadow from AppShadows.navShadow (acts as 1px top border)
4 tabs: Home | Progress | Groups | Profile

Active tab:
  Icon color: AppColors.textPrimary
  Label: AppTextStyles.navLabelActive
  Home tab only: icon inside Container(
    decoration: BoxDecoration(
      color: AppColors.surfaceMuted,
      borderRadius: BorderRadius.circular(999),
    ),
    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
  )

Inactive tab:
  Icon color: AppColors.inactive
  Label: AppTextStyles.navLabelInactive

Profile tab active:
  Replace icon widget with Container(
    width: 28, height: 28,
    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
  )

FAB:
  Positioned — bottom: navHeight + fabMargin, right: fabMargin
  Container(60×60, shape: CircleBorder):
    color: AppColors.primaryDark   ← teal dark
    Icon(LucideIcons.plus, 28px, Colors.white)
    boxShadow: AppShadows.fabShadow
  onTap: trigger action grid modal
```

### 8.2 FAB Action Grid Modal

```
Trigger: FAB tap
Animation: ScaleTransition from FAB origin point, 250ms Curves.easeOutBack
Dismiss: tap outside, 180ms FadeTransition + ScaleTransition

Overlay: ModalBarrier color: Color(0x59000000)

Grid layout:
  Positioned just above FAB, right-aligned
  GridView 2×2, mainAxisSpacing: 10, crossAxisSpacing: 10

Each ActionGridCell:
  Container:
    color: AppColors.surface
    borderRadius: BorderRadius.circular(16)
    padding: EdgeInsets.all(20)
    width: (screenWidth - 16 - 16 - 10) / 2   (~160px)
    height: 140
    boxShadow: AppShadows.cardShadow
  InkWell(borderRadius: BorderRadius.circular(16)):
    Column(mainAxisAlignment: center):
      Icon(icon, size: 36, color: AppColors.textPrimary)
      SizedBox(height: 10)
      Text(label, 15px w600 AppColors.textPrimary, textAlign: center)

4 cells (row-major order):
  [Log Exercise — footprints]  [Saved Foods — bookmark ]
  [Food Database — search   ]  [Scan Food   — scanLine ]
```

### 8.3 Calorie Ring Card

```
Container:
  color: AppColors.surface
  borderRadius: BorderRadius.circular(20)
  padding: EdgeInsets.all(20)
  boxShadow: AppShadows.cardShadow

Row(mainAxisAlignment: MainAxisAlignment.spaceBetween):

  // Left
  Column(crossAxisAlignment: CrossAxisAlignment.start):
    TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: caloriesLeft),
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (_, val, __) => Text(val.toString(), style: AppTextStyles.heroNumber),
    )
    SizedBox(height: 4)
    RichText(text: TextSpan(children: [
      TextSpan(text: "Calories ", style: 14px w400 AppColors.textSecondary),
      TextSpan(text: "left",     style: 14px w700 AppColors.textPrimary),
    ]))

  // Right — donut ring
  SizedBox(96×96):
    CustomPaint(
      painter: DonutRingPainter(
        trackColor:    AppColors.ringTrack,
        progressColor: AppColors.primaryMid,   ← teal arc
        strokeWidth:   10.0,
        progress:      consumed / total,        // 0.0 – 1.0
        startAngle:    -pi / 2,                 // 12 o'clock
      ),
    )
    // Center icon (Stack):
    Center:
      SvgPicture.asset('assets/icons/flame_gradient.svg', width: 24, height: 24)
      // OR Icon(LucideIcons.flame, size: 24, color: AppColors.primaryDark)
```

### 8.4 Macro Tiles Row

```
Row(children: [Expanded(ProteinTile), Expanded(CarbsTile), Expanded(FatsTile)])
MainAxisSpacing: 10

MacroTile:
  Container:
    color: AppColors.surface
    borderRadius: BorderRadius.circular(16)
    padding: EdgeInsets.all(14)
    boxShadow: AppShadows.cardShadow

  Column(crossAxisAlignment: CrossAxisAlignment.start):
    Text(value,  AppTextStyles.macroValue)         // "159g"
    SizedBox(height: 2)
    RichText:
      Text(macroName + " ", 13px w600 AppColors.textPrimary)
      Text("left",           13px w400 AppColors.textSecondary)
    Spacer
    Center:
      SizedBox(56×56):
        CustomPaint(painter: DonutRingPainter(
          trackColor: AppColors.ringTrack,
          progressColor: macroColor,   // protein/carbs/fats tint
          strokeWidth: 6.0,
          progress: consumed / total,
          startAngle: -pi / 2,
        ))
        Center: Icon(macroIcon, size: 20, color: macroColor)

Macro configs:
  Protein: value="159g", color=AppColors.protein, icon=LucideIcons.beef
  Carbs:   value="268g", color=AppColors.carbs,   icon=LucideIcons.wheat
  Fats:    value="63g",  color=AppColors.fats,    icon=LucideIcons.droplets
```

### 8.5 Weekly Calendar Strip

```
SizedBox(height: 72):
  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly):
    7× DayCircle(dayAbbrev, date, state)

DayCircle:
  Column(mainAxisAlignment: center):
    Text(abbrev, 11px w500 AppColors.inactive)   // "Thu"
    SizedBox(height: 4)
    Container(width: 36, height: 36, child: CustomPaint(painter: DayCirclePainter(state)))

DayCirclePainter states:
  default  → dashed circle border Color(0xFFCECECE) 1.5px
             (Flutter has no native dashed border — paint manually in CustomPainter)
  today    → solid circle border 2px AppColors.primaryDark   ← teal
  selected → solid circle border 2px AppColors.danger (#E53935)
  future   → dashed circle Color(0xFFDDDDDD) 1.5px, dimmer

Number inside: 14px, weight/color by state:
  default:  w500 AppColors.textSecondary
  today:    w700 AppColors.textPrimary
  selected: w600 AppColors.danger
  future:   w400 Color(0xFFCECECE)
```

### 8.6 Weight Card

```
Container:
  color: AppColors.surface
  borderRadius: BorderRadius.circular(20)
  padding: EdgeInsets.all(20)
  width: (screenWidth - AppSpacing.screenPadding * 2 - 12) / 2
  boxShadow: AppShadows.cardShadow

Column(crossAxisAlignment: CrossAxisAlignment.center):
  Text("My Weight",  AppTextStyles.cardHeading)
  SizedBox(height: 6)
  Text("55 kg",      AppTextStyles.cardValue)
  SizedBox(height: 8)
  ClipRRect(borderRadius: BorderRadius.circular(4)):
    LinearProgressIndicator(
      value: currentWeight / goalWeight,
      backgroundColor: AppColors.ringTrack,
      valueColor: AlwaysStoppedAnimation(AppColors.primary),   ← teal bar
      minHeight: 3,
    )
  SizedBox(height: 8)
  Row(mainAxisAlignment: center):
    Text("Goal  ", 13px AppColors.inactive)
    Text("75 kg", 13px w600 AppColors.textPrimary)
  SizedBox(height: 10)
  Text("Next weight-in: 5d", 12px AppColors.textPlaceholder)
```

### 8.7 Day Streak Card

```
Container:
  color: AppColors.surface
  borderRadius: BorderRadius.circular(20)
  padding: EdgeInsets.all(20)
  width: (screenWidth - AppSpacing.screenPadding * 2 - 12) / 2
  boxShadow: AppShadows.cardShadow

Column(crossAxisAlignment: CrossAxisAlignment.center):
  Stack(alignment: Alignment.bottomCenter):
    SvgPicture.asset('assets/icons/flame_gradient.svg', width: 48, height: 52)
    Padding(bottom: 8):
      Text(streakCount.toString(), 22px w700 AppColors.fire)
    // Sparkle accents: 3× Container(3×3, circle, AppColors.carbs)
    //   positioned top-left, top-right, right-mid via Positioned

  SizedBox(height: 6)
  Text("Day streak", 14px w700 AppColors.fire)
  SizedBox(height: 10)

  Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly):
    ["S","M","T","W","T","F","S"].mapIndexed((i, letter) =>
      Column:
        Text(letter, 11px AppColors.inactive)
        SizedBox(height: 4)
        Container(
          width: 10, height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completedDays[i] ? AppColors.fireLight : AppColors.streakInactive,
          ),
        )
    )
```

### 8.8 Goal Progress Chart

```
Package: fl_chart — LineChart widget

Container:
  color: AppColors.surface
  borderRadius: BorderRadius.circular(20)
  padding: EdgeInsets.all(20)
  boxShadow: AppShadows.cardShadow

// Time range tabs
Row:
  ["90 Days", "6 Months", "1 Year", "All time"].map((tab) =>
    GestureDetector(onTap: setRange):
      AnimatedContainer(
        duration: 150ms,
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.surfaceMuted : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(tab,
          style: selected
            ? TextStyle(15px w700 AppColors.textPrimary)
            : TextStyle(15px w400 AppColors.textSecondary),
        ),
      )
  )

SizedBox(height: 16)

LineChart(
  LineChartData(
    gridData: FlGridData(
      drawHorizontalLine: true,
      getDrawingHorizontalLine: (_) => FlLine(
        color: AppColors.border, strokeWidth: 1, dashArray: [4, 4],
      ),
      drawVerticalLine: false,
    ),
    borderData: FlBorderData(show: false),
    titlesData: FlTitlesData(
      leftTitles: AxisTitles(sideTitles: SideTitles(
        showTitles: true, reservedSize: 36,
        getTitlesWidget: (val, _) => Text(val.toStringAsFixed(1), 12px AppColors.inactive),
      )),
      bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles:  AxisTitles(sideTitles: SideTitles(showTitles: false)),
      topTitles:    AxisTitles(sideTitles: SideTitles(showTitles: false)),
    ),
    lineBarsData: [
      LineChartBarData(
        spots: weightDataPoints,
        color: AppColors.primaryDark,    ← teal line
        barWidth: 2,
        isCurved: true,
        dotData: FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          gradient: LinearGradient(
            colors: [AppColors.primary.withOpacity(0.15), Colors.transparent],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
      ),
    ],
    lineTouchData: LineTouchData(
      touchTooltipData: LineTouchTooltipData(
        tooltipBgColor: AppColors.primaryDark,
        getTooltipItems: (spots) => spots.map((s) =>
          LineTooltipItem("${s.y} kg", const TextStyle(color: Colors.white, fontSize: 12))
        ).toList(),
      ),
    ),
  ),
  swapAnimationDuration: const Duration(milliseconds: 400),
  swapAnimationCurve: Curves.easeInOut,
)
```

### 8.9 Profile Screen

```
Scaffold(backgroundColor: AppColors.background)
SingleChildScrollView(padding: EdgeInsets.symmetric(horizontal: 16)):

  SizedBox(height: 16)

  // User card
  Container(color: surface, radius: 20, padding: 16, shadow: cardShadow):
    Row:
      CircleAvatar(
        radius: 26, backgroundColor: AppColors.surfaceMuted,
        child: Icon(LucideIcons.user, size: 28, color: AppColors.inactive),
      )
      SizedBox(width: 14)
      Column(crossAxisAlignment: start):
        Row:
          Text("Enter your name", 17px w500 AppColors.textPlaceholder)
          SizedBox(width: 6)
          Icon(LucideIcons.pencil, size: 16, color: AppColors.inactive)
        Text("23 years old", 13px AppColors.textSecondary)

  SizedBox(height: 20)
  _SectionLabel("Invite friends")

  // Invite card
  Container(color: surface, radius: 20, padding: 16, shadow: cardShadow):
    Row:
      Icon(LucideIcons.userPlus, 22px AppColors.textPrimary)
      SizedBox(width: 12)
      Expanded: Column:
        Text("Refer a friend and earn \$10", 15px w600)
        SizedBox(height: 2)
        Text("Earn \$10 per friend that signs up with your promo code.", 13px AppColors.textSecondary)

  SizedBox(height: 20)
  _SectionLabel("Account")

  _GroupedListCard([
    _SettingsRow(LucideIcons.badgeCheck, "Personal details"),
    _SettingsRow(LucideIcons.settings2,  "Preferences"),
    _SettingsRow(LucideIcons.languages,  "Language"),
  ])

  SizedBox(height: 20)
  _SectionLabel("Goals & Tracking")

  _GroupedListCard([
    _SettingsRow(LucideIcons.circleDashed, "Edit Nutrition Goals"),
  ])

// ── Sub-widgets ───────────────────────────────────────────

_SectionLabel(String label):
  Padding(bottom: 8, left: 4):
    Text(label, 13px w500 AppColors.inactive)

_GroupedListCard(List<Widget> rows):
  Container(color: surface, radius: 20, shadow: cardShadow):
    Column: rows.separated(by: Divider(color: AppColors.border, height: 1, indent: 52))

_SettingsRow(IconData icon, String label):
  ListTile(
    leading: Icon(icon, size: 22, color: AppColors.textPrimary),
    title: Text(label, 15px w500 AppColors.textPrimary),
    trailing: Icon(LucideIcons.chevronRight, size: 18, color: AppColors.inactive),
    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
  )
```

### 8.10 Log Food Screen

```
Scaffold(backgroundColor: AppColors.surface)

AppBar:
  backgroundColor: AppColors.surface, elevation: 0
  leading: IconButton(icon: Icon(LucideIcons.arrowLeft), color: textPrimary)
  title: Text("Log food", 17px w600, textAlign: center)
  centerTitle: true

// Custom tab row (NOT TabBar — match Cal AI style)
Row(padding: horizontal 16):
  ["All", "My meals", "My foods", "Saved scans"].mapIndexed((i, tab) =>
    GestureDetector(onTap: () => setTab(i)):
      Column:
        Text(tab,
          style: active
            ? TextStyle(15px w700 AppColors.textPrimary)
            : TextStyle(15px w400 AppColors.inactive),
        )
        SizedBox(height: 4)
        Container(
          height: 2,
          width: textWidth,
          color: active ? AppColors.primary : Colors.transparent,   ← teal underline
        )
  )

SizedBox(height: 12)

// Search input
Container(
  margin: EdgeInsets.symmetric(horizontal: 16),
  decoration: BoxDecoration(
    color: AppColors.surface,
    border: Border.all(color: AppColors.textPrimary, width: 2),
    borderRadius: BorderRadius.circular(14),
  ),
  child: TextField(
    decoration: InputDecoration(
      hintText: "Describe what you ate",
      hintStyle: TextStyle(15px AppColors.textPlaceholder),
      border: InputBorder.none,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  ),
)

SizedBox(height: 16)
Padding(horizontal: 16): Text("Suggestions", AppTextStyles.sectionHeader)
SizedBox(height: 10)

// Suggestion list
ListView(padding: horizontal 16):
  SuggestionRow items, gap: 8

SuggestionRow:
  Container(
    color: AppColors.surfaceMuted,
    borderRadius: BorderRadius.circular(14),
    padding: EdgeInsets.all(16),
  ):
    Row(mainAxisAlignment: spaceBetween):
      Column(crossAxisAlignment: start):
        Text(name, AppTextStyles.bodyBold)
        SizedBox(height: 4)
        Row:
          Icon(LucideIcons.flame, 16, AppColors.fire)
          Text(" $cal cal · $unit", AppTextStyles.bodyRegular)
      GestureDetector(onTap: addFood, hitTestBehavior: opaque):
        SizedBox(44×44, child: Center(Icon(LucideIcons.plus, 20, AppColors.textPrimary)))

// Fixed bottom action bar
Positioned(bottom: safeBottom, left: 0, right: 0):
  Container(
    color: AppColors.surface,
    padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
    child: Row:
      Expanded(_PillOutlineButton(LucideIcons.fileText, "Manual"))
      SizedBox(width: 10)
      Expanded(_PillOutlineButton(LucideIcons.mic,      "Voice Log"))
  )

_PillOutlineButton:
  OutlinedButton(
    style: OutlinedButton.styleFrom(
      side: BorderSide(color: AppColors.textPrimary, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      minimumSize: Size(double.infinity, 52),
      foregroundColor: AppColors.textPrimary,
    ),
    child: Row:
      Icon(icon, 18)
      SizedBox(width: 8)
      Text(label, AppTextStyles.buttonLabel.copyWith(color: AppColors.textPrimary))
  )
```

### 8.11 Scan Food Camera Screen

```
Full screen: camera package CameraPreview

Stack:
  Expanded(CameraPreview(controller))

  // Top buttons
  Positioned(top: safeTop + 10, left: 16, right: 16):
    Row(mainAxisAlignment: spaceBetween):
      _CameraRoundButton(LucideIcons.x)
      _CameraRoundButton(LucideIcons.info)

  // Scan frame (CustomPaint — corners only, no full rect)
  Center:
    AnimatedOpacity(opacity: pulseValue, duration: 600ms):
      CustomPaint(
        size: Size(240, 240),
        painter: ScanCornersPainter(
          color: Colors.white, strokeWidth: 3,
          cornerLength: 28, cornerRadius: 6,
        ),
      )

  // Mode selector row
  Positioned(bottom: safeBottom + 100):
    SingleChildScrollView(scrollDirection: horizontal, padding: horizontal 16):
      Row(gap: 8): 4× _CameraModeCard

  // Shutter row
  Positioned(bottom: safeBottom + 28):
    Row(mainAxisAlignment: center):
      _CameraRoundButton(LucideIcons.zapOff)
      SizedBox(width: 70)
      _ShutterButton()
      SizedBox(width: 70 + 44)

_CameraRoundButton:
  Container(44×44, CircleBorder, color: Colors.white.withOpacity(0.85)):
    Icon(icon, 20, AppColors.textPrimary)

_ShutterButton:
  GestureDetector(onTap: captureImage):
    Container(72×72, CircleBorder, color: Colors.white.withOpacity(0.90)):
      Icon(LucideIcons.camera, 28, AppColors.textPrimary)

_CameraModeCard:
  Container(color: Colors.white, radius: 14, padding: symmetric(h:10, v:12)):
    Column(mainAxisSize: min):
      Icon(icon, 22, AppColors.textPrimary)
      SizedBox(height: 4)
      Text(label, 12px w500 AppColors.textPrimary)

Modes: [Scan Food/scanLine] [Barcode/barcode] [Food label/tag] [Gallery/image]
```

### 8.12 Log Exercise Screen

```
Scaffold(backgroundColor: AppColors.background)
AppBar: leading arrow | "Exercise" center | elevation 0 | bg: background

SingleChildScrollView(padding: horizontal 16):
  SizedBox(height: 8)
  Text("Log Exercise", AppTextStyles.screenTitle)
  SizedBox(height: 20)
  4× ExerciseOptionCard, gap: 10

ExerciseOptionCard:
  InkWell(borderRadius: 16, onTap: navigate):
    Container(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      boxShadow: AppShadows.cardShadow,
    ):
      Row:
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: AppColors.surfaceMuted,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, 20, AppColors.textPrimary),
        )
        SizedBox(width: 14)
        Expanded: Column(crossAxisAlignment: start):
          Text(name, 16px w600 AppColors.textPrimary)
          SizedBox(height: 2)
          Text(desc, 13px AppColors.textSecondary)

Options:
  [footprints / "Run"            / "Running, jogging, sprinting, etc."]
  [dumbbell   / "Weight lifting" / "Machines, free weights, etc."     ]
  [pencil     / "Describe"       / "Write your workout in text"        ]
  [flame      / "Manual"         / "Enter exactly how many calories you burned"]
```

### 8.13 Run — Set Intensity Screen

```
Scaffold(backgroundColor: AppColors.background)
AppBar: leading arrow | Row(Icon(footprints,18) + Text(" Run")) center

SingleChildScrollView(padding: horizontal 16):

  // Section header
  Row:
    Icon(LucideIcons.sparkles, 18, AppColors.inactive)
    SizedBox(width: 6)
    Text("Set intensity", AppTextStyles.sectionHeader)
  SizedBox(height: 12)

  // Intensity card
  Container(color: AppColors.surfaceMuted, radius: 16):
    Column:
      IntensityRow("High",   "Sprinting – 14 mph (4 minute miles)",  Intensity.high)
      Divider(color: AppColors.border, height: 1, indent: 16, endIndent: 16)
      IntensityRow("Medium", "Jogging – 6 mph (10 minute miles)",    Intensity.medium)
      Divider(color: AppColors.border, height: 1, indent: 16, endIndent: 16)
      IntensityRow("Low",    "Chill walk – 3 mph (20 minute miles)", Intensity.low)

  IntensityRow:
    ListTile(
      title: Text(label,
        style: selected ? 18px w700 AppColors.textPrimary : 16px w500 AppColors.textPrimary),
      subtitle: Text(desc, 13px AppColors.textSecondary),
      trailing: Radio<Intensity>(
        value: option, groupValue: selectedIntensity,
        activeColor: AppColors.primaryDark,   ← teal radio
        onChanged: setIntensity,
      ),
    )

  SizedBox(height: 24)

  // Duration header
  Row:
    Icon(LucideIcons.timer, 18, AppColors.inactive)
    SizedBox(width: 6)
    Text("Duration", AppTextStyles.sectionHeader)
  SizedBox(height: 12)

  // Chips
  SingleChildScrollView(scrollDirection: Axis.horizontal):
    Row(gap: 8): ["15 mins","30 mins","60 mins","90 mins","120 mins"].map(_DurationChip)

  _DurationChip:
    GestureDetector(onTap: selectDuration):
      AnimatedContainer(
        duration: 150ms, curve: Curves.ease,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDark : AppColors.surface,
          border: Border.all(
            color: selected ? AppColors.primaryDark : AppColors.border, width: 1.5),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(label, style: TextStyle(
          fontSize: 14,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? Colors.white : AppColors.textPrimary,
        )),
      )

  SizedBox(height: 10)

  // Manual input
  Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(14),
    ),
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    child: TextField(
      keyboardType: TextInputType.number,
      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
      decoration: InputDecoration(border: InputBorder.none),
    ),
  )
  SizedBox(height: 80) // spacer for fixed CTA

// Fixed CTA
Positioned(bottom: safeBottom + 16, left: 16, right: 16):
  SizedBox(
    height: 56, width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryDark,   ← teal
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      child: Text("Continue", style: AppTextStyles.buttonLabel),
      onPressed: onContinue,
    ),
  )
```

---

## 9. Navigation Header (Home Screen)

```dart
// In the Home screen AppBar or custom header widget
Container(
  color: AppColors.background,
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [

    // Left: avocado logo + app name
    Row(children: [
      SvgPicture.asset(
        'assets/icons/avocado.svg',
        width: 26, height: 26,
        colorFilter: ColorFilter.mode(AppColors.primary, BlendMode.srcIn),
      ),
      SizedBox(width: 6),
      Text("GojoCalories",
        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
    ]),

    // Right: streak pill
    Container(
      padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [BoxShadow(color: Color(0x1A000000), blurRadius: 6, offset: Offset(0,1))],
      ),
      child: Row(children: [
        SvgPicture.asset('assets/icons/flame_gradient.svg', width: 20, height: 20),
        SizedBox(width: 6),
        Text("$streakCount",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      ]),
    ),

  ]),
)
```

---

## 10. Recently Uploaded Food Row

```dart
Container(
  color: AppColors.surface,
  borderRadius: BorderRadius.circular(20),
  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  margin: EdgeInsets.symmetric(horizontal: 16),
  child: Row(children: [

    // Thumbnail
    ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: imageUrl, width: 64, height: 64, fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          width: 64, height: 64, color: AppColors.surfaceMuted,
          child: Icon(LucideIcons.image, size: 28, color: AppColors.inactive),
        ),
        errorWidget: (_, __, ___) => Container(
          width: 64, height: 64, color: AppColors.surfaceMuted,
          child: Icon(LucideIcons.image, size: 28, color: AppColors.inactive),
        ),
      ),
    ),
    SizedBox(width: 12),

    // Name + calories
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(foodName, style: AppTextStyles.bodyBold, maxLines: 2, overflow: TextOverflow.ellipsis),
      SizedBox(height: 4),
      Row(children: [
        Icon(LucideIcons.flame, size: 14, color: AppColors.fire),
        Text(" $calories calories", style: AppTextStyles.bodyRegular),
      ]),
    ])),

    // Time
    Text(timeString, style: TextStyle(fontSize: 12, color: AppColors.inactive)),
  ]),
)
```

---

## 11. Screen Map

```
App
├── Home (Tab 1)
│   ├── Header: avocado logo + streak pill
│   ├── Weekly calendar strip (teal border for today)
│   ├── Calorie ring card (teal arc)
│   ├── Macro tiles row (protein=salmon / carbs=gold / fats=violet)
│   └── Recently uploaded food list
│
├── Progress (Tab 2)
│   ├── Weight card (teal progress bar) + Day streak card (row)
│   ├── Time range tabs (90D / 6M / 1Y / All)
│   └── Goal progress chart (teal line + teal gradient fill)
│
├── Groups (Tab 3)
│   └── [Group feed / leaderboard — TBD]
│
├── Profile (Tab 4)
│   ├── User card (avatar + name + age)
│   ├── Invite friends card
│   ├── Account settings group (Personal / Preferences / Language)
│   └── Goals & Tracking (Edit Nutrition Goals)
│
└── FAB (teal dark) → Action Grid Modal
    ├── Log Exercise → LogExerciseScreen
    │   ├── Run → RunIntensityScreen → Continue → log saved
    │   ├── Weight Lifting → WeightLiftingScreen
    │   ├── Describe → DescribeWorkoutScreen
    │   └── Manual → ManualCaloriesScreen
    ├── Saved Foods → SavedFoodsScreen
    ├── Food Database → FoodDatabaseScreen
    └── Scan Food → ScanFoodScreen (camera)
        ├── Scan Food (capture → Gemini Flash → result)
        ├── Barcode (mobile_scanner)
        ├── Food Label (image_picker → Gemini Flash)
        └── Gallery (image_picker)
```

---

## 12. Animations & Transitions (Flutter)

| Interaction | Flutter API | Duration | Curve |
|---|---|---|---|
| Tab switch | `IndexedStack` + `AnimatedOpacity` | 220ms | `Curves.easeInOut` |
| FAB → action grid open | `ScaleTransition(scale: CurvedAnimation(Curves.easeOutBack))` | 250ms | `Curves.easeOutBack` |
| Action grid dismiss | `ScaleTransition` + `FadeTransition` | 180ms | `Curves.easeIn` |
| Calorie ring fill | `AnimationController` + `Tween<double>`, custom `CustomPainter` | 600ms | `Curves.easeOut` |
| Macro ring fill each | Same + `Future.delayed(100ms * index)` stagger | 500ms | `Curves.easeOut` |
| Card press feedback | `GestureDetector` + `AnimatedScale(scale: 0.97)` | 100ms | `Curves.ease` |
| Duration chip select | `AnimatedContainer` bg + border color | 150ms | `Curves.ease` |
| Intensity radio | `Radio` `activeColor: AppColors.primaryDark` | 150ms | `Curves.ease` |
| Scan corners pulse | `AnimationController(repeat: true)` opacity 0.6→1.0 | 1200ms | `Curves.easeInOut` |
| Food list stagger | Wrap items in `FadeTransition` + `SlideTransition` indexed delay | 200ms | `Curves.easeOut` |
| Hero number count-up | `TweenAnimationBuilder<int>(tween: IntTween(0, value))` | 300ms | `Curves.easeOut` |
| Chart draw | `fl_chart swapAnimationDuration` | 400ms | `Curves.easeInOut` |

---

## 13. Empty & Loading States

```
// Calorie ring — no data logged yet
Painter: draw full ringTrack arc, no progress arc
Center: Icon(LucideIcons.flame, opacity: 0.3, color: AppColors.primaryDark)

// Macro ring — no data
Full ringTrack arc, macro icon at opacity 0.25

// Weight chart — only one data point
Single horizontal flat line at current weight value
lineChartData with single FlSpot, dashed via custom canvas

// Food list — empty state
Center(Column):
  Icon(LucideIcons.utensilsCrossed, size: 48, color: AppColors.inactive)
  SizedBox(height: 12)
  Text("No food logged yet", 15px AppColors.inactive)

// Skeleton / shimmer loading (shimmer package):
  ShimmerEffect children shaped like real components:
  - shimmerBaseColor:      AppColors.surfaceMuted
  - shimmerHighlightColor: AppColors.surface

// Image load / error fallback
  Container(64×64, AppColors.surfaceMuted):
    Icon(LucideIcons.image, 28, AppColors.inactive)
```

---

## 14. Flutter Frontend Package List

```yaml
# pubspec.yaml dependencies

dependencies:
  flutter:
    sdk: flutter

  # Fonts
  google_fonts: ^6.2.0         # Inter font

  # Icons
  lucide_icons_flutter: ^0.0.4  # Lucide icon set
  flutter_svg: ^2.0.10          # SVG rendering (avocado, flame)

  # Navigation
  go_router: ^14.0.0

  # Charts
  fl_chart: ^0.69.0             # Line chart (progress), donut rings via CustomPainter

  # Camera & scanning
  camera: ^0.11.0
  mobile_scanner: ^5.0.0        # Barcode scanning
  image_picker: ^1.1.0          # Gallery / food label photos

  # Animations
  animations: ^2.0.11           # Page transitions (OpenContainer, FadeThrough)

  # State management
  flutter_riverpod: ^2.5.1

  # Local data
  shared_preferences: ^2.3.0
  drift: ^2.18.0                # SQLite for food logs, weight history

  # Images
  cached_network_image: ^3.3.1  # Async food thumbnails with cache

  # Loading shimmer
  shimmer: ^3.0.0

  # Utilities
  intl: ^0.19.0                 # Date / number formatting
```

---

## 15. Asset File Structure

```
assets/
├── icons/
│   ├── avocado.svg              ← app logo
│   │   Spec: pear-silhouette path, fill: AppColors.primary (#00B4CC)
│   │   Pit: ellipse, fill: AppColors.primaryDark (#007D8F)
│   │   ViewBox: 0 0 32 32
│   │
│   ├── flame_gradient.svg       ← streak flame
│   │   Spec: flame path, linearGradient #FFA726 → #FF7A00 (top → bottom)
│   │   3× sparkle dots ✦ around it in #FFD700
│   │   ViewBox: 0 0 48 56
│   │
│   └── protein_drumstick.svg    ← optional, if LucideIcons.beef isn't ideal
│
└── images/
    └── food_placeholder.png     ← gray bowl illustration for empty thumbnail
```

---

## 16. Accessibility Checklist (Flutter)

- [ ] All `Icon` widgets wrapped in `Semantics(label: "...")` where standalone
- [ ] All `GestureDetector` / `InkWell` targets ≥ 44×44 logical pixels
- [ ] Tappable areas expanded with `SizedBox` + `hitTestBehavior: opaque` where icon is smaller
- [ ] `Semantics(button: true)` on all custom tappable containers
- [ ] Streak card: `Semantics(label: "$count day streak, started on Sunday")`
- [ ] Calorie ring: `Semantics(label: "$remaining calories remaining of $total goal")`
- [ ] Macro tiles: `Semantics(label: "$value grams of $macro remaining")`
- [ ] Color not sole indicator — all rings also display numeric values
- [ ] `MediaQuery.textScaler` support — no fixed widget heights that clip scaled text
- [ ] Test at 1.5× text scale: hero numbers, macro values, card labels must not truncate
- [ ] `MediaQuery.boldTextEnabled` respected — no forced `FontWeight` on body copy
- [ ] Camera screen: `Semantics(liveRegion: true)` for scan status announcements

---

## 17. Key UX Rules

1. **No emojis as structural icons** — `lucide_icons_flutter` + `flutter_svg` only
2. **Bottom nav max 4 tabs** — Home, Progress, Groups, Profile
3. **FAB always visible** — `Positioned` in `Stack`, never hidden on scroll
4. **All teal: primary `#00B4CC`, CTA/active use `primaryDark #007D8F`**
5. **Cards always white `#FFFFFF` on gray `#F2F2F7` background** — never gray on gray
6. **Ring progress clockwise from 12 o'clock** — `startAngle: -pi / 2`
7. **Macro colors are strictly semantic** — protein=salmon, carbs=gold, fats=violet; never swap
8. **Camera frame: corner arcs only** — `ScanCornersPainter`, no full rectangle
9. **Duration chips (not slider)** — thumb-friendly, immediate selection feedback
10. **Voice Log always beside Manual** — equal status, side-by-side pill buttons
11. **`AnimatedContainer` for all state changes** — never instant color/size swaps
12. **Avocado SVG always tinted `AppColors.primary`** via `ColorFilter.mode(BlendMode.srcIn)`
13. **Count-up numbers on screen entry** — `TweenAnimationBuilder<int>` for all big stats
14. **`fl_chart` line chart gets gradient fill below the line** — `BarAreaData` with teal opacity

---

*GojoCalories — Design Prompt v2.0*
*Teal-first rebrand · Avocado identity · Flutter frontend spec · No backend content*