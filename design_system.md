# GojoCalories Design System

This document outlines the core design language used in the GojoCalories application, derived from the Flutter theme configuration.

## 1. Typography

The application uses the **Inter** font family via `GoogleFonts.interTextTheme()`.

### Text Styles

| Style Name | Font Size | Weight | Line Height | Color Reference | Used For |
|---|---|---|---|---|---|
| **heroNumber** | 48 | Extra Bold (w800) | 1.0 | textPrimary | Large numbers |
| **screenTitle** | 32 | Bold (w700) | 1.2 | textPrimary | Main screen titles |
| **sectionHeader** | 20 | Bold (w700) | 1.3 | textPrimary | Headers within screens |
| **cardHeading** | 14 | Regular (w400) | 1.4 | textSecondary | Titles on cards |
| **cardValue** | 28 | Bold (w700) | 1.1 | textPrimary | Values on cards |
| **macroValue** | 20 | Bold (w700) | 1.2 | textPrimary | Macronutrient values |
| **macroLabel** | 13 | Regular (w400) | 1.4 | textSecondary | Macronutrient labels |
| **navLabelActive** | 11 | SemiBold (w600) | 1.0 | textPrimary | Active bottom nav item |
| **navLabelInactive** | 11 | Regular (w400)| 1.0 | inactive | Inactive bottom nav item |
| **bodyBold** | 15 | SemiBold (w600) | 1.4 | textPrimary | Emphasized body text |
| **bodyRegular** | 13 | Regular (w400) | 1.4 | textSecondary | Standard body text |
| **buttonLabel** | 16 | SemiBold (w600) | 1.0 | Colors.white | Text inside buttons |

## 2. Color Palette

The color system is organized logically by backgrounds, text, borders, primary accents, semantic macros, and states.

### Backgrounds & Surfaces
- **background**: `#F2F2F7` - Screen background (iOS system gray)
- **surface**: `#FFFFFF` - Card background
- **surfaceMuted**: `#F5F5F5` - Inner tiles, exercise rows
- **surfaceTealLight**: `#E0F8FB` - Teal-tinted background (chip active)

### Text
- **textPrimary**: `#0A0A0A` - Main text color
- **textSecondary**: `#6B6B6B` - Secondary text
- **textPlaceholder**: `#ADADAD` - Placeholder text

### Borders & Dividers
- **border**: `#E8E8E8` - Standard border color
- **ringTrack**: `#EBEBEB` - Track color for rings/circular progress
- **inactive**: `#9E9E9E` - Disabled or inactive elements

### Primary Teal Palette
- **primary**: `#00B4CC` - Main teal accent
- **primaryDark**: `#007D8F` - Call to Action (CTA) buttons, Floating Action Button (FAB)
- **primaryLight**: `#E0F8FB` - Selected chip background
- **primaryMid**: `#00A0B4` - Calorie ring arc fill

### Macro Semantic Colors
- **fire**: `#FF7A00` - Streak, flame icon
- **fireLight**: `#FFA726` - Streak dot filled
- **protein**: `#FF6B6B` - Salmon-red (Protein indicator)
- **carbs**: `#D4A017` - Wheat-gold (Carbs indicator)
- **fats**: `#8B6FD4` - Soft violet (Fats indicator)

### States
- **danger**: `#E53935` - Selected date, errors
- **streakInactive**: `#D9D9D9` - Inactive streak indicator

## 3. Theme Configuration

The master `ThemeData` (light theme) is configured with:

- **Brightness**: Light
- **Primary Color**: `AppColors.primary`
- **Scaffold Background**: `AppColors.background`
- **Color Scheme**:
  - `primary`: AppColors.primary
  - `secondary`: AppColors.primaryDark
  - `surface`: AppColors.surface
  - `error`: AppColors.danger
- **AppBar Theme**:
  - `backgroundColor`: AppColors.surface
  - `elevation`: 0 (Flat, no shadow)
  - `centerTitle`: true
  - `iconTheme`: AppColors.textPrimary
- **Text Selection Theme**:
  - `cursorColor`: AppColors.primaryDark
