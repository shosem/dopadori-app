---
name: Aetheric Calm
colors:
  surface: '#f6faff'
  surface-dim: '#d1dbe5'
  surface-bright: '#f6faff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#ebf5ff'
  surface-container: '#e5eff9'
  surface-container-high: '#dfe9f3'
  surface-container-highest: '#dae4ee'
  on-surface: '#131d24'
  on-surface-variant: '#41474e'
  inverse-surface: '#283239'
  inverse-on-surface: '#e8f2fc'
  outline: '#71787f'
  outline-variant: '#c1c7cf'
  surface-tint: '#2e6388'
  primary: '#2b6085'
  on-primary: '#ffffff'
  primary-container: '#47799f'
  on-primary-container: '#fcfcff'
  inverse-primary: '#9accf6'
  secondary: '#4d6170'
  on-secondary: '#ffffff'
  secondary-container: '#cee2f5'
  on-secondary-container: '#526575'
  tertiary: '#b71422'
  on-tertiary: '#ffffff'
  tertiary-container: '#db3237'
  on-tertiary-container: '#fffbff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#cbe6ff'
  primary-fixed-dim: '#9accf6'
  on-primary-fixed: '#001e30'
  on-primary-fixed-variant: '#0c4b6f'
  secondary-fixed: '#d1e5f8'
  secondary-fixed-dim: '#b5c9db'
  on-secondary-fixed: '#091d2b'
  on-secondary-fixed-variant: '#364958'
  tertiary-fixed: '#ffdad7'
  tertiary-fixed-dim: '#ffb3ae'
  on-tertiary-fixed: '#410004'
  on-tertiary-fixed-variant: '#930014'
  background: '#f6faff'
  on-background: '#131d24'
  surface-variant: '#dae4ee'
typography:
  headline-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '600'
    lineHeight: '1.2'
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: '1.2'
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '500'
    lineHeight: '1.4'
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: '1.6'
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.6'
  label-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '500'
    lineHeight: '1.2'
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: '1.2'
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  xs: 4px
  sm: 12px
  md: 24px
  lg: 48px
  xl: 80px
  gutter: 20px
  margin-mobile: 24px
  margin-desktop: 64px
---

## Brand & Style

This design system is defined by an atmosphere of tranquility, clarity, and weightlessness. It aims to evoke a sense of mental "breathing room" for the user, utilizing a soft, airy aesthetic that prioritizes emotional well-being and focus.

The visual style is a hybrid of **Minimalism** and **Glassmorphism**. It leverages expansive, desaturated fields of color to reduce cognitive load, paired with subtle translucent layers that suggest depth without creating visual clutter. The interface feels light, open, and responsive, moving away from heavy, solid blocks of color toward a more ethereal, light-filled experience.

## Colors

The palette is anchored in "Aether Blue," a soft, calming mid-tone that serves as the primary action color. The background strategy uses very light, desaturated blue-greys to create an expansive feel.

- **Primary:** A clear, calming blue used for high-emphasis actions and meaningful states.
- **Secondary:** A muted, translucent blue-grey for secondary interactions and background partitioning.
- **Tertiary:** A vibrant coral/red, used sparingly as a "pulse" or focal point to draw immediate attention.
- **Neutral:** A range of cool greys with blue undertones to maintain the "airy" temperature of the design.

In dark mode, surfaces should transition to deep, desaturated teals rather than pure black, maintaining a high degree of transparency and backdrop-blur effects to preserve the "glassy" feel.

## Typography

This design system utilizes **Inter** exclusively to maintain a functional, modern, and highly legible environment. The type scale is designed to feel generous and unhurried. 

Headlines use tighter letter-spacing and heavier weights to provide structure against the soft background colors. Body text is set with comfortable line-heights to ensure effortless scanning. Labels are occasionally set in medium or semi-bold weights to provide hierarchy without needing to increase size or color contrast excessively.

## Layout & Spacing

The layout philosophy follows a **Fluid Grid** model with an emphasis on "Safe Air"—intentional whitespace that prevents the UI from feeling cramped. 

- **Desktop:** A 12-column grid with generous 64px outer margins. Content should be centered with a maximum readable width.
- **Mobile:** A 4-column grid with 24px margins to accommodate touch targets comfortably.
- **Spacing Rhythm:** Based on an 8px baseline. Use `lg` and `xl` spacing for section verticality to maintain the "airy" brand promise. Elements should feel like they have room to float.

## Elevation & Depth

Depth is conveyed through **Glassmorphism** and **Tonal Layers** rather than traditional heavy shadows.

1.  **Backdrop Blurs:** Surfaces that sit above the main background must use a `blur(20px)` or higher effect with a semi-transparent white (light mode) or semi-transparent deep navy (dark mode) fill.
2.  **Thin Outlines:** Instead of shadows, use 1px solid borders with very low opacity (10-15%) to define the edges of containers.
3.  **Soft Ambient Glows:** If a shadow is required for extreme hierarchy (e.g., a modal), use a very large spread (32px+) with a low-opacity tint of the primary blue color rather than neutral black.

## Shapes

The shape language is consistently **Rounded**. This choice removes "visual sharpness," contributing to the overall calming effect of the system. 

- **Standard Containers:** Use the `rounded-lg` (1rem) setting.
- **Interactive Elements:** Buttons and input fields should use the `rounded-xl` (1.5rem) or fully pill-shaped (rounded-full) geometry to emphasize their approachability.
- **Small Elements:** Chips and badges should use pill shapes.

## Components

- **Buttons:** Primary buttons are solid "Aether Blue" with white text. Secondary buttons use a glassmorphic style: a translucent blue-grey background with the primary blue color for the label.
- **Chips:** Highly rounded, using the secondary color at 20% opacity for the container and a darker version of the same hue for the text.
- **Input Fields:** Subtly recessed or glass-styled with 1.5px borders that highlight in the primary color when focused.
- **Cards:** Use `rounded-lg` with a thin, low-opacity border and a subtle backdrop blur. No heavy drop shadows.
- **The "Pulse":** A specific component for focus or status—a small, circular element using the Tertiary color, often accompanied by a soft, repeating scale animation (the "breath" effect).
- **Navigation:** Bottom navigation (mobile) or top bars (desktop) should be highly translucent, allowing background colors to bleed through, blurring the content behind them to maintain context.