---
name: GojoCalories
version: alpha
colors:
  primary: "#00B4CC"
  primary-dark: "#007D8F"
  primary-light: "#E0F8FB"
  background: "#F2F2F7"
  surface: "#FFFFFF"
  surface-muted: "#F5F5F5"
  text-primary: "#0A0A0A"
  text-secondary: "#6B6B6B"
  text-placeholder: "#ADADAD"
  border: "#E8E8E8"
  fire: "#FF7A00"
  protein: "#FF6B6B"
  carbs: "#D4A017"
  fats: "#8B6FD4"
  danger: "#E53935"
typography:
  hero:
    fontFamily: Inter
    fontSize: 3rem
    fontWeight: 800
  title:
    fontFamily: Inter
    fontSize: 2rem
    fontWeight: 700
  header:
    fontFamily: Inter
    fontSize: 1.25rem
    fontWeight: 700
  body-lg:
    fontFamily: Inter
    fontSize: 1rem
    fontWeight: 600
  body-md:
    fontFamily: Inter
    fontSize: 0.9375rem
    fontWeight: 600
  body-sm:
    fontFamily: Inter
    fontSize: 0.8125rem
    fontWeight: 400
  label:
    fontFamily: Inter
    fontSize: 0.6875rem
    fontWeight: 600
rounded:
  sm: 12px
  md: 16px
  lg: 20px
  full: 999px
spacing:
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 32px
  xxl: 48px
components:
  card:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.lg}"
    padding: "{spacing.md}"
  button-primary:
    backgroundColor: "{colors.primary-dark}"
    textColor: "{colors.surface}"
    rounded: "{rounded.full}"
    padding: 14px
  input-field:
    backgroundColor: "{colors.surface}"
    rounded: "{rounded.sm}"
---

## Overview

GojoCalories is a clean, modern, and accessible nutrition tracking platform. The design is rooted in a "Primary Teal" palette that evokes health, energy, and precision. The interface uses a light background with subtle gradients and elevated cards to create a sense of depth and hierarchy.

## Colors

The palette is centered around vibrant Teal and semantic macro colors.

- **Primary Teal (#00B4CC):** The core brand color, used for accents and progress rings.
- **Teal Dark (#007D8F):** Used for primary CTAs and high-emphasis elements.
- **Background (#F2F2F7):** A soft gray foundation that provides a premium, "iOS-like" surface.
- **Macro Colors:** Semantic colors for Protein (Salmon), Carbs (Gold), and Fats (Violet) to provide quick visual cues.

## Typography

We use **Inter** for all text to ensure maximum readability and a modern aesthetic.

- **Hero Numbers:** Used for calorie counts and primary metrics.
- **Screen Titles:** Large, bold headings for page entry points.
- **Body Text:** Clear, well-spaced type for food logs and metadata.

## Layout & Spacing

A 16px screen padding is the standard. Cards are separated by 12px-20px gaps to maintain a clean "bento-box" style layout.

## Shapes

Soft, generous corner radii (16px-20px) are used for all cards to create a friendly and approachable feel. Buttons and chips use fully rounded (pill) shapes for distinct interactivity.
