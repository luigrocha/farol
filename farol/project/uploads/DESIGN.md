# Design System: High-End Editorial Finance

## 1. Overview & Creative North Star
**The Creative North Star: "The Financial Sanctuary"**

This design system moves beyond the utility of a standard banking app to create a high-end, editorial experience. It is designed to feel like a premium concierge service—calm, authoritative, and sophisticated. We achieve this by rejecting the "boxed-in" layout of traditional fintech. Instead, we embrace **Organic Precision**: a layout strategy that uses intentional asymmetry, expansive negative space, and a "tonal-first" approach to depth. 

The goal is to make the Brazilian user feel a sense of "financial breathing room." By utilizing a high-contrast typography scale (Manrope for displays, Inter for utility) and layered, translucent surfaces, the interface feels less like a database and more like a curated digital magazine.

---

### 2. Colors: Tonal Architecture
The palette is rooted in deep, trustworthy navies (`primary`) and growth-oriented greens (`secondary`), but the "premium" feel comes from how these colors are layered rather than how they are outlined.

*   **The "No-Line" Rule:** 1px solid borders are strictly prohibited for sectioning. Boundaries must be defined solely through background color shifts. For example, a `surface-container-low` section should sit on a `surface` background to create a "ghost" boundary.
*   **Surface Hierarchy & Nesting:** Treat the UI as physical layers of fine paper. 
    *   **Level 0 (Base):** `surface` (#faf9fc).
    *   **Level 1 (Sections):** `surface-container-low` (#f4f3f6).
    *   **Level 2 (Active Cards):** `surface-container-lowest` (#ffffff) for maximum "lift" and clarity.
*   **The Glass & Gradient Rule:** For main CTAs and premium balance cards, use a linear gradient from `primary_container` (#1b3a5c) to `primary` (#002444) at a 135-degree angle. For floating navigation or modals, use `surface_container_lowest` with a 20px backdrop-blur and 80% opacity to achieve a "frosted glass" effect.
*   **Signature Textures:** Use the `tertiary_fixed` (#71f8e4) as a subtle glow or "aura" behind high-value benefits (like Swile integrations) to provide a soft, digital soul.

---

### 3. Typography: Editorial Authority
We use a dual-font strategy to balance character with legibility. 

*   **Display & Headlines (Manrope):** Used for large balance amounts and section headers. The wider apertures and geometric forms of Manrope convey a modern, architectural strength.
*   **Body & Labels (Inter):** Used for all functional data. Inter provides the "Apple-style" neutrality required for complex financial lists and dense information.

**Hierarchy Strategy:** 
*   **Hero Balance:** `display-lg` (Manrope). This is the focal point. Always paired with `on_surface` for maximum contrast.
*   **Section Headers:** `headline-sm` (Manrope) in `on_surface_variant`. Use lowercase or wide letter-spacing for a "gallery" feel.
*   **Data Points:** `title-md` (Inter) for transaction names; `label-md` for metadata (dates/categories).

---

### 4. Elevation & Depth: Tonal Layering
Traditional shadows are often "dirty." In this system, we use light and tone to define space.

*   **The Layering Principle:** Avoid elevation shadows on static elements. Instead, place a `surface-container-lowest` card on a `surface-container` background. The change in hex value provides enough "lift" for the eye without visual clutter.
*   **Ambient Shadows:** If an element must float (e.g., a Bottom Sheet or FAB), use an extra-diffused shadow: `box-shadow: 0 12px 40px rgba(26, 28, 30, 0.06)`. Note the 6% opacity—it should be felt, not seen.
*   **The "Ghost Border" Fallback:** If accessibility requires a stroke, use `outline-variant` (#c3c6cf) at 15% opacity. It must look like a faint indentation in the paper, not a line drawn on top.
*   **Glassmorphism:** Navigation bars should use `surface_bright` at 85% opacity with a `blur(12px)` effect, allowing the vibrant Brazilian brand colors (Green/Teal) to bleed through softly as the user scrolls.

---

### 5. Components: Fluid Primitives

*   **Buttons:**
    *   **Primary:** `primary_container` background with `on_primary_container` text. Use `xl` (1.5rem) corner radius. Use a subtle inner-glow (top-down) for a tactile, "pressed" look.
    *   **Secondary:** Ghost style. No background, `primary` text, and a `surface-dim` background on hover only.
*   **Cards:** 
    *   **Constraint:** No dividers. Use 24px of vertical padding (`spacing-xl`) to separate content blocks.
    *   **Corners:** Use `xl` (1.5rem / 24px) for main containers and `lg` (1rem / 16px) for nested items.
*   **Lists:** 
    *   Forbid horizontal lines between transactions. Instead, use alternating `surface` and `surface-container-low` backgrounds or simply generous white space.
*   **Inputs:** 
    *   Floating label style. The input container should be `surface-container-highest` with a bottom-only "active" indicator in `secondary` (#006d3f) to signal growth and action.
*   **Financial Progress Bars:**
    *   Use `secondary_fixed` (#9bf6ba) as the track and `secondary` (#006d3f) as the fill. This tonal pairing suggests depth and "filling a vessel."

---

### 6. Do’s and Don'ts

#### Do:
*   **Do** use asymmetrical margins. A 24px left margin and 16px right margin can create a sophisticated, editorial "pull."
*   **Do** use `secondary` (Green) for all positive financial trends. Growth is the primary motivator for the user.
*   **Do** prioritize "Glanceability." A user should understand their net worth in under 1 second of looking at the screen.

#### Don't:
*   **Don't** use pure black (#000000). Use `on_surface` (#1a1c1e) for text to keep the interface feeling "soft."
*   **Don't** use 100% opaque borders. They interrupt the "Financial Sanctuary" flow and make the app feel like a legacy bank.
*   **Don't** cram icons. If an icon is used, it must be a light-weight (2pt stroke), open-path style to match the "San Francisco" aesthetic.