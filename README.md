---
name: MejorDía
colors:
  surface: '#f9f9f9'
  surface-dim: '#dadada'
  surface-bright: '#f9f9f9'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f4f3f3'
  surface-container: '#eeeeee'
  surface-container-high: '#e8e8e8'
  surface-container-highest: '#e2e2e2'
  on-surface: '#1a1c1c'
  on-surface-variant: '#454652'
  inverse-surface: '#2f3131'
  inverse-on-surface: '#f1f1f1'
  outline: '#767683'
  outline-variant: '#c6c5d4'
  surface-tint: '#4c56af'
  primary: '#000666'
  on-primary: '#ffffff'
  primary-container: '#1a237e'
  on-primary-container: '#8690ee'
  inverse-primary: '#bdc2ff'
  secondary: '#1b6d24'
  on-secondary: '#ffffff'
  secondary-container: '#a0f399'
  on-secondary-container: '#217128'
  tertiary: '#400003'
  on-tertiary: '#ffffff'
  tertiary-container: '#670007'
  on-tertiary-container: '#ff635a'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#e0e0ff'
  primary-fixed-dim: '#bdc2ff'
  on-primary-fixed: '#000767'
  on-primary-fixed-variant: '#343d96'
  secondary-fixed: '#a3f69c'
  secondary-fixed-dim: '#88d982'
  on-secondary-fixed: '#002204'
  on-secondary-fixed-variant: '#005312'
  tertiary-fixed: '#ffdad6'
  tertiary-fixed-dim: '#ffb4ac'
  on-tertiary-fixed: '#410003'
  on-tertiary-fixed-variant: '#93000e'
  background: '#f9f9f9'
  on-background: '#1a1c1c'
  surface-variant: '#e2e2e2'
typography:
  display-lg:
    fontFamily: Hanken Grotesk
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.5px
  headline-lg:
    fontFamily: Hanken Grotesk
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
  headline-lg-mobile:
    fontFamily: Hanken Grotesk
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
  title-md:
    fontFamily: Hanken Grotesk
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Hanken Grotesk
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Hanken Grotesk
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-sm:
    fontFamily: Hanken Grotesk
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.5px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 4px
  margin-mobile: 16px
  margin-desktop: 24px
  gutter: 12px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 24px
---

## Brand & Style
The brand personality is disciplined yet encouraging, acting as a reliable companion for personal growth. The design system follows a **Corporate Modern** style, specifically evolving the principles of **Material Design 3** to create a structured, professional, and highly legible interface. 

The goal is to evoke a sense of order and accomplishment. By utilizing a "Surface-Container" architecture, the UI feels organized and approachable. The aesthetic is clean and focuses on functional clarity, using generous whitespace and intentional elevation to guide the user's focus toward their daily habits and progress milestones.

## Colors
The color palette is anchored by a deep, authoritative Blue (`Primary`) to instill trust and focus. Success states for completed habits use a grounded Green (`Secondary`), while missed or failed streaks are clearly indicated with a bold Red (`Tertiary`).

- **Primary**: Used for key actions, active states, and brand-level elements.
- **Success/Secondary**: High-contrast indicator for completed habits and positive trends.
- **Error/Tertiary**: Immediate visual feedback for broken streaks or missed goals.
- **Neutral**: Applied to "unregistered" or future days in the calendar to prevent visual clutter.
- **Surface**: Backgrounds use a very light gray to reduce eye strain while providing a subtle contrast against white card elements.

## Typography
This design system utilizes **Hanken Grotesk** for its sharp, contemporary feel and excellent legibility in data-dense views. 

The type hierarchy is strictly enforced to ensure users can scan their daily stats quickly. Large displays are used for streak counts, while Title and Body styles handle habit descriptions and settings. Labels are used specifically for calendar dates and metadata. On mobile devices, Headlines are downscaled to ensure content remains above the fold.

## Layout & Spacing
The layout follows a **fluid grid** model optimized for mobile-first interaction. 

- **Grid**: A 4-column grid for mobile and an 8-column grid for tablet.
- **Rhythm**: All spacing is based on a 4px baseline unit. 
- **Margins**: 16px horizontal margins on mobile screens to maximize horizontal space for habit titles while maintaining breathing room.
- **Stacking**: Use 16px (stack-md) for vertical spacing between habit cards and 8px (stack-sm) for elements within a card.

## Elevation & Depth
In line with Material Design 3, this design system uses **Tonal Layers** combined with **Ambient Shadows**.

- **Level 0 (Surface)**: Background (#F8F9FA).
- **Level 1 (Cards)**: White background with a soft, diffused shadow (Blur: 8px, Y: 2px, Opacity: 4% Black). Use this for standard habit items.
- **Level 2 (Active/Pressed)**: Tonal overlay of the primary color (5% opacity) and a slightly deeper shadow to indicate interaction.
- **Floating Action Buttons (FAB)**: Highest elevation level to signify the primary "Add Habit" action.

## Shapes
The shape language is friendly and modern, utilizing **Rounded** corners to make the UI feel less rigid.

- **Small Components (Checkboxes, Chips)**: 4px - 8px radius.
- **Medium Components (Habit Cards, Input Fields)**: 16px radius.
- **Large Components (Bottom Sheets, Modal Containers)**: 24px radius (top corners).
- **Buttons**: Fully pill-shaped (rounded-xl) to distinguish them as interactive triggers.

## Components

### Buttons
- **Primary**: Pill-shaped, Primary Blue background, White text.
- **Ghost**: No background, Primary Blue border and text, used for secondary actions like "Cancel".

### Habit Cards
- White background, 16px corner radius, Level 1 elevation.
- Includes a leading icon area and a trailing "Status Indicator" (Success/Error/Neutral).

### Calendar Indicators
- Circular or "Squircle" shapes. 
- **Success**: Solid green circle with a white checkmark.
- **Failure**: Solid red circle with a white 'X'.
- **Unregistered**: Neutral gray outline with no fill.

### Input Fields
- Outlined style with 16px corner radius.
- Labels should transition to a smaller "Label-sm" size when the field is focused.

### Progress Bars
- Thick, 8px height with fully rounded ends.
- Background: Neutral Gray.
- Fill: Primary Blue or Success Green depending on goal completion.

### Bottom Navigation
- Uses a surface-tinted background with active states indicated by pill-shaped overlays behind icons.